import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models/cards.dart';
import 'models/units.dart';

/// A deck made by the player.
class CustomDeck {
  CustomDeck(this.name, this.army, this.cards);
  String name;
  List<String> army; // hero ids (a hero id can repeat up to the copies owned)
  List<String> cards; // tactic card ids

  Map<String, Object?> toJson() => {'name': name, 'army': army, 'cards': cards};

  static CustomDeck? fromJson(Object? j) {
    if (j is! Map) return null;
    final n = j['name'];
    final a = j['army'];
    final c = j['cards'];
    if (n is! String || a is! List || c is! List) return null;
    return CustomDeck(n, [for (final x in a) '$x'], [for (final x in c) '$x']);
  }

  DeckDef toDef(int index) => DeckDef('custom$index', cards, army, label: name);
}

/// Player profile: XP, gold, card collection and custom decks.
/// Saved as JSON in the platform application-support directory. Every storage
/// call is guarded so a storage failure cannot crash the game.
class Profile {
  static int xp = 0;
  static int gold = 300;
  static Map<String, int> owned = Map.of(starterCards);
  static List<CustomDeck> customDecks = [];
  static Set<String> storyDone = {};
  static int towerBest = 0; // highest tower floor cleared
  static Map<String, int> towerLive = {}; // best floor of each Sariyya tower
  static bool _loaded = false;

  static Future<Directory> get _dir async {
    final sep = Platform.pathSeparator;
    try {
      // Preserve the existing Windows save location so V4 profiles migrate
      // without any manual export or import.
      final env = Platform.environment;
      if (Platform.isWindows && env['APPDATA'] != null) {
        return Directory('${env['APPDATA']}${sep}TheLastMessage');
      }
      if (Platform.isAndroid || Platform.isIOS) {
        return await getApplicationSupportDirectory();
      }
      if (Platform.isMacOS && env['HOME'] != null) {
        return Directory('${env['HOME']}/Library/Application Support/TheLastMessage');
      }
      if (Platform.isLinux && env['HOME'] != null) {
        return Directory('${env['HOME']}/.local/share/TheLastMessage');
      }
    } catch (_) {}
    return Directory('${Directory.systemTemp.path}${sep}TheLastMessage');
  }

  static Future<File> get _file async =>
      File('${(await _dir).path}${Platform.pathSeparator}save.json');

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = await _file;
      if (!await f.exists()) {
        // Migrate V4 Android/Linux fallback saves from the temporary folder
        // into the persistent application-support directory.
        final legacy = File('${Directory.systemTemp.path}${Platform.pathSeparator}TheLastMessage${Platform.pathSeparator}save.json');
        if (await legacy.exists()) {
          await f.parent.create(recursive: true);
          await legacy.copy(f.path);
        }
      }
      if (!await f.exists()) {
        // Very old builds stored only XP in a temp file.
        final old = File('${Directory.systemTemp.path}${Platform.pathSeparator}tlm_xp.txt');
        if (await old.exists()) xp = int.tryParse((await old.readAsString()).trim()) ?? 0;
        return;
      }
      final j = jsonDecode(await f.readAsString());
      if (j is! Map) return;
      xp = (j['xp'] as num?)?.toInt() ?? 0;
      gold = (j['gold'] as num?)?.toInt() ?? 300;
      final o = j['owned'];
      if (o is Map) {
        final m = <String, int>{};
        o.forEach((k, v) {
          if (unitById.containsKey('$k') && v is num && v > 0) m['$k'] = v.toInt();
        });
        if (m.isNotEmpty) owned = m;
      }
      towerBest = (j['tower'] as num?)?.toInt() ?? 0;
      final tl = j['towerLive'];
      if (tl is Map) {
        towerLive = {for (final e in tl.entries) '${e.key}': (e.value as num?)?.toInt() ?? 0};
      }
      final sd = j['story'];
      if (sd is List) storyDone = {for (final x in sd) '$x'};
      final d = j['decks'];
      if (d is List) {
        customDecks = [
          for (final x in d)
            if (CustomDeck.fromJson(x) != null) CustomDeck.fromJson(x)!
        ];
      }
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      await (await _dir).create(recursive: true);
      await (await _file).writeAsString(jsonEncode({
        'xp': xp,
        'gold': gold,
        'owned': owned,
        'decks': [for (final d in customDecks) d.toJson()],
        'story': storyDone.toList(),
        'tower': towerBest,
        'towerLive': towerLive,
      }));
    } catch (_) {}
  }

  // ------------------------------------------------------------ XP / gold

  static Future<void> addXp(int n) async {
    xp += n; // updated immediately, saved right after
    await save();
  }

  static Future<void> addGold(int n) async {
    gold += n;
    await save();
  }

  /// (level, xp inside this level, xp needed for the next level)
  static (int, int, int) progress([int? total]) {
    var left = total ?? xp;
    var level = 1;
    var need = 100;
    while (left >= need) {
      left -= need;
      level++;
      need += 50;
    }
    return (level, left, need);
  }

  static int get level => progress().$1;

  // --------------------------------------------------------------- story

  /// Marks a chapter as finished and gives its reward card (first time only).
  static void completeChapter(String id, String rewardCard) {
    if (!storyDone.add(id)) return;
    if (rewardCard.isNotEmpty) owned[rewardCard] = copiesOf(rewardCard) + 1;
    save();
  }

  // ----------------------------------------------------------- collection

  static int copiesOf(String id) => owned[id] ?? 0;

  /// Buys [id] for [price]; false if you cannot afford it.
  static bool buy(String id, int price) {
    if (gold < price) return false;
    gold -= price;
    owned[id] = copiesOf(id) + 1;
    save();
    return true;
  }

  /// Adds a card (pack opening). Returns true if it was a duplicate.
  static bool addCard(String id) {
    final dup = copiesOf(id) > 0;
    owned[id] = copiesOf(id) + 1;
    save();
    return dup;
  }

  // ------------------------------------------------------------- decks

  static void addDeck(CustomDeck d) {
    customDecks.add(d);
    save();
  }

  static void removeDeck(CustomDeck d) {
    customDecks.remove(d);
    save();
  }

  /// All decks you can play: the two presets, then your own.
  static List<DeckDef> get playableDecks => [
        ...decks,
        for (var i = 0; i < customDecks.length; i++)
          if (customDecks[i].army.length >= minArmy) customDecks[i].toDef(i),
      ];
}
