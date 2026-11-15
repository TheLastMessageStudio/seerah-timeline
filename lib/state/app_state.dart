import 'dart:convert';
import 'package:flutter/services.dart';
import '../l10n/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../services/patreon_service.dart';

class AppState extends ChangeNotifier {
  late Repository repo;
  final patreon = PatreonService();
  late SharedPreferences _prefs;

  bool ready = false;
  Set<String> favorites = {};
  Set<String> read = {};
  List<String> history = [];
  final Map<String, String> bookPositions = {};
  ThemeMode themeMode = ThemeMode.system;
  double textScale = 1.0;
  String lang = 'fr';
  bool debugPremium = false; // uniquement en mode debug
  bool debugAdminPreview = false; // aperçu administrateur : contourne les dates de sortie
  final Map<String, DateTime> scheduledEventDates = {};
  List<Map<String, dynamic>> releaseScheduleRows = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getString('lang');
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    lang = Strings.supported.contains(saved)
        ? saved!
        : (Strings.supported.contains(device) ? device : 'fr');
    Strings.lang = lang;
    repo = await Repository.load(lang: lang);
    try {
      final rawSchedule = await rootBundle.loadString('assets/data/release_schedule.json');
      final rows = (jsonDecode(rawSchedule) as List).cast<Map<String, dynamic>>();
      releaseScheduleRows = rows;
      for (final row in rows) {
        final parsed = DateTime.parse(row['releaseDate'] as String);
        final date = DateTime(parsed.year, parsed.month, parsed.day, 10);
        for (final id in (row['eventIds'] as List).cast<String>()) { scheduledEventDates[id] = date; }
      }
    } catch (_) { /* le projet reste utilisable sans calendrier éditorial */ }
    favorites = (_prefs.getStringList('favorites') ?? []).toSet();
    read = (_prefs.getStringList('read') ?? []).toSet();
    history = _prefs.getStringList('history') ?? [];
    for (final key in _prefs.getKeys().where((k) => k.startsWith('book_position_'))) {
      final value = _prefs.getString(key);
      if (value != null && value.isNotEmpty) bookPositions[key.substring('book_position_'.length)] = value;
    }
    debugPremium = kDebugMode && (_prefs.getBool('debug_premium_preview') ?? false);
    debugAdminPreview = kDebugMode && (_prefs.getBool('debug_admin_preview') ?? false);
    themeMode = ThemeMode.values[(_prefs.getInt('theme') ?? 0).clamp(0, 2)];
    textScale = _prefs.getDouble('scale') ?? 1.0;
    patreon.addListener(notifyListeners);
    ready = true;
    notifyListeners();
    patreon.init();
  }

  // ----- Premium -----
  bool get isPremium => patreon.premium || (kDebugMode && (debugPremium || debugAdminPreview));

  bool hasEntitlement(String code) =>
      patreon.entitlements.contains(code) ||
      (kDebugMode && (debugPremium || debugAdminPreview));

  bool isWaitingForRelease(String eventId) {
    if (kDebugMode && debugAdminPreview) return false;
    final release = scheduledEventDates[eventId];
    return release != null && DateTime.now().isBefore(release);
  }

  bool _hasReleasedRelatedEvent(Iterable<Event> events) =>
      events.isEmpty || events.any((event) => !isWaitingForRelease(event.id));

  bool canOpenEvent(Event e) =>
      !isWaitingForRelease(e.id) && (hasEntitlement('events') || (repo.period(e.periodId)?.free ?? false));

  bool canOpenPerson(Person p) =>
      _hasReleasedRelatedEvent(repo.eventsOfPerson(p.id)) && (hasEntitlement('biographies') || p.free);

  bool canOpenPlace(Place p) =>
      _hasReleasedRelatedEvent(repo.eventsOfPlace(p.id)) && (hasEntitlement('map') || p.free);

  bool periodUnlocked(Period p) => hasEntitlement('events') || p.free;

  void setDebugAdminPreview(bool v) {
    debugAdminPreview = kDebugMode && v;
    _prefs.setBool('debug_admin_preview', debugAdminPreview);
    notifyListeners();
  }

  void setDebugPremium(bool v) {
    debugPremium = kDebugMode && v;
    _prefs.setBool('debug_premium_preview', debugPremium);
    notifyListeners();
  }

  // ----- Lecture -----
  Event? get lastEvent => history.isEmpty ? null : repo.event(history.first);

  List<Event> get latestReleasedEvents {
    final now = DateTime.now();
    final releasedRows = releaseScheduleRows.where((row) {
      final parsed = DateTime.parse(row['releaseDate'] as String);
      return !now.isBefore(DateTime(parsed.year, parsed.month, parsed.day, 10));
    }).toList();
    final ids = releasedRows.isEmpty
        ? const ['birth_prophet', 'abdullah_death', 'halimah_nursing', 'chest_opening', 'aminah_death']
        : (releasedRows.last['eventIds'] as List).cast<String>();
    return ids.map(repo.event).whereType<Event>().toList();
  }
  int get readCount => repo.events.where((e) => read.contains(e.id)).length;

  double progress(String periodId) {
    final list = repo.eventsOfPeriod(periodId);
    if (list.isEmpty) return 0;
    return list.where((e) => read.contains(e.id)).length / list.length;
  }

  void visit(String id) {
    history.remove(id);
    history.insert(0, id);
    if (history.length > 15) history = history.sublist(0, 15);
    _prefs.setStringList('history', history);
    notifyListeners();
  }

  void toggleRead(String id) {
    read.contains(id) ? read.remove(id) : read.add(id);
    _prefs.setStringList('read', read.toList());
    notifyListeners();
  }

  void toggleFavorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    _prefs.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  void resetProgress() {
    read.clear();
    history.clear();
    _prefs.setStringList('read', []);
    _prefs.setStringList('history', []);
    notifyListeners();
  }

  // ----- Bibliothèque : reprise de lecture -----
  String? bookPosition(String bookId) => bookPositions[bookId];

  Future<void> saveBookPosition(String bookId, String passageId) async {
    bookPositions[bookId] = passageId;
    await _prefs.setString('book_position_$bookId', passageId);
    notifyListeners();
  }

  // ----- Préférences -----
  Future<void> setLang(String l) async {
    if (l == lang) return;
    lang = l;
    Strings.lang = l;
    _prefs.setString('lang', l);
    repo = await Repository.load(lang: l);
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    _prefs.setInt('theme', m.index);
    notifyListeners();
  }

  void setTextScale(double v) {
    textScale = v;
    _prefs.setDouble('scale', v);
    notifyListeners();
  }
}
