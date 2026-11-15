import '../live/live_game.dart';
import '../models/cards.dart';
import '../models/units.dart';

/// "La Tour" — endless-style end-game mode. Each floor is a rush battle
/// against a bigger, stronger Quraysh-style army. Every 5th floor is a boss
/// floor and a checkpoint; milestone floors also give a hero card.
class Tower {
  static const int checkpointEvery = 5;
  static const int maxFloor = 50;

  static bool isBoss(int floor) => floor % checkpointEvery == 0;

  /// The floor you restart from after a defeat (last cleared checkpoint + 1).
  static int startFloor(int best) => (best ~/ checkpointEvery) * checkpointEvery + 1;

  /// AI strength bonus for [floor] (see Game.aiBoost).
  static int boost(int floor) => floor - 1;

  static const List<String> _bosses = ['ikrima', 'sibaa', 'abusufyan', 'khalid', 'talhatalha'];
  static const List<String> _elites = ['ikrima', 'wahshi', 'sibaa', 'ubayy', 'talhatalha', 'abusufyan'];

  static String bossOf(int floor) => _bosses[(floor ~/ checkpointEvery - 1) % _bosses.length];

  /// Army of the AI on [floor]: more units and tougher heroes as you climb.
  static DeckDef deckFor(int floor, DeckDef cardsFrom) {
    final size = (5 + floor ~/ 2).clamp(5, 14);
    const base = ['spearmen', 'swordsman', 'archer', 'rider', 'guard', 'skirmisher'];
    final army = <String>[];
    for (var i = 0; i < size; i++) {
      army.add(base[(i + floor) % base.length]);
    }
    // Elite heroes from floor 3, one more every 4 floors.
    final elites = floor < 3 ? 0 : 1 + (floor - 3) ~/ 4;
    for (var i = 0; i < elites && i < 4; i++) {
      army[army.length - 1 - i] = _elites[(floor + i) % _elites.length];
    }
    if (isBoss(floor)) army[0] = bossOf(floor);
    return DeckDef('tower', cardsFrom.cardIds, army);
  }

  /// Gold for clearing [floor].
  static int gold(int floor) => 40 + floor * 15 + (isBoss(floor) ? 100 : 0);

  static int xp(int floor) => 30 + floor * 8;

  /// Hero card given on boss floors (null on other floors).
  static String? rewardCard(int floor) {
    if (!isBoss(floor)) return null;
    final maxRarity = (1 + floor ~/ 10).clamp(1, 4);
    final pool = [for (final h in heroTypes) if (h.rarity >= 1 && h.rarity <= maxRarity) h.id];
    if (pool.isEmpty) return null;
    return pool[(floor * 7 + floor ~/ 5) % pool.length];
  }

  // ------------------------------------------------------------------
  // Sariyya (real-time) towers: same floors, rewards and checkpoints as the
  // classic tower, but two different towers with their own enemy and rules.

  static const List<LiveTowerDef> liveTowers = [desertTower, fortressTower];

  static const LiveTowerDef desertTower = LiveTowerDef(
    id: 'sahra',
    nameFr: 'Tour du Désert',
    nameEn: 'Desert Tower',
    descFr: 'Cavaliers, chameaux et éclaireurs : une armée rapide qui contourne et frappe les villes. Ennemis plus rapides, un peu plus fragiles.',
    descEn: 'Riders, camels and scouts: a fast army that flanks and raids your towns. Faster but slightly more fragile enemies.',
    rules: LiveRules.desert,
    pool: ['rider', 'scout', 'camel', 'skirmisher', 'rider', 'archer', 'camel', 'swordsman'],
  );

  static const LiveTowerDef fortressTower = LiveTowerDef(
    id: 'hisn',
    nameFr: 'Tour de la Forteresse',
    nameEn: 'Fortress Tower',
    descFr: 'Gardes, lanciers et archers : une armée lente et solide qui défend. Ennemis plus résistants, tour de base plus puissante.',
    descEn: 'Guards, spearmen and archers: a slow, sturdy army that defends. Tougher enemies and a stronger base tower.',
    rules: LiveRules.fortress,
    pool: ['guard', 'spearmen', 'archer', 'swordsman', 'guard', 'archer', 'spearmen', 'skirmisher'],
  );

  static LiveTowerDef liveTower(String id) => liveTowers.firstWhere((t) => t.id == id, orElse: () => desertTower);

  /// Difficulty level of the enemy AI on [floor].
  static int liveLevel(int floor) => 4 + floor;

  /// Number of rounds to win a floor: boss floors are a best of 3.
  static int liveRounds(int floor) => isBoss(floor) ? 3 : 1;

  /// Enemy cards of [tower] on [floor]: bigger every few floors, with elite
  /// heroes first (they start on the map) and a boss on boss floors.
  static List<UnitType> liveArmy(String towerId, int floor) {
    final def = liveTower(towerId);
    final size = (7 + floor ~/ 3).clamp(7, 12);
    final ids = <String>[for (var i = 0; i < size; i++) def.pool[(i + floor) % def.pool.length]];
    final elites = floor < 2 ? 0 : (1 + (floor - 2) ~/ 4).clamp(1, 4);
    for (var i = 0; i < elites; i++) {
      ids[i] = _elites[(floor + i) % _elites.length];
    }
    if (isBoss(floor)) ids[0] = bossOf(floor);
    return [for (final id in ids) unitById[id]!];
  }
}

class LiveTowerDef {
  const LiveTowerDef({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.descFr,
    required this.descEn,
    required this.rules,
    required this.pool,
  });
  final String id, nameFr, nameEn, descFr, descEn;
  final LiveRules rules;
  final List<String> pool;
}
