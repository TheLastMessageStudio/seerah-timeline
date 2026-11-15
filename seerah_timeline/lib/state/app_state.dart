import '../l10n/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../services/purchase_service.dart';

class AppState extends ChangeNotifier {
  late Repository repo;
  final purchases = PurchaseService();
  late SharedPreferences _prefs;

  bool ready = false;
  Set<String> favorites = {};
  Set<String> read = {};
  List<String> history = [];
  ThemeMode themeMode = ThemeMode.system;
  double textScale = 1.0;
  String lang = 'fr';
  bool debugPremium = false; // uniquement en mode debug

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getString('lang');
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    lang = Strings.supported.contains(saved)
        ? saved!
        : (Strings.supported.contains(device) ? device : 'fr');
    Strings.lang = lang;
    repo = await Repository.load(lang: lang);
    favorites = (_prefs.getStringList('favorites') ?? []).toSet();
    read = (_prefs.getStringList('read') ?? []).toSet();
    history = _prefs.getStringList('history') ?? [];
    themeMode = ThemeMode.values[(_prefs.getInt('theme') ?? 0).clamp(0, 2)];
    textScale = _prefs.getDouble('scale') ?? 1.0;
    purchases.addListener(notifyListeners);
    ready = true;
    notifyListeners();
    purchases.init();
  }

  // ----- Premium -----
  bool get isPremium => purchases.premium || (kDebugMode && debugPremium);
  bool canOpenEvent(Event e) => isPremium || (repo.period(e.periodId)?.free ?? false);
  bool canOpenPerson(Person p) => isPremium || p.free;
  bool canOpenPlace(Place p) => isPremium || p.free;
  bool periodUnlocked(Period p) => isPremium || p.free;

  void setDebugPremium(bool v) {
    debugPremium = v;
    notifyListeners();
  }

  // ----- Lecture -----
  Event? get lastEvent => history.isEmpty ? null : repo.event(history.first);
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
