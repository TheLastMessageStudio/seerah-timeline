import 'dart:math';

import '../models/battlefield.dart';
import '../models/game_map.dart';
import '../models/side.dart';
import '../models/terrain.dart';
import '../models/units.dart';

/// All the numbers that decide how the real-time mode feels. Change them here.
class LiveTuning {
  static const int extraRows = 4; // longer battlefield
  static const double speedPerMove = 0.22; // cells / second for each point of "move"
  static const double hpMultiplier = 2.2; // sturdier units
  static const double damageScale = 0.5; // multiplies (attack - defense)
  static const double minDamage = 0.7;
  static const double meleeCooldown = 2.6; // seconds between two attacks
  static const double rangedCooldown = 3.2;
  static const double cavalryCooldown = 2.0;
  static const double aggroExtra = 2.0; // idle units notice enemies this far beyond their range
  static const double baseHp = 120;
  static const double baseDamageScale = 0.35;
  static const double baseTowerDamage = 1.0;
  static const double baseTowerRange = 3.4;
  static const double baseTowerCooldown = 1.5;
  static const double prepSeconds = 20; // preparation: place cards, queue orders, nobody moves
  static const double battleSeconds = 240; // then a round lasts at most this long
  static const double maxEnergy = 10;
  static const double startEnergy = 6;
  static const double energyPerSecond = 1 / 2.6;
  static const double cardCooldown = 12; // a dead unit's card comes back after this
  static const int handSize = 4;
  static const int startingUnits = 3; // already on the map when the round starts

  // towns (the four villages on the flanks)
  static const double townRadius = 1.4; // units this close capture the town
  static const double captureSeconds = 5;
  static const double townZoneHalf = 4.0; // a captured town opens a (2*half)^2 deployment box

  // formations
  static const double formationSpacing = 0.95;

  // AI difficulty ("level"): the higher, the harder.
  static double aiHp(int level) => min(2.0, 1 + level * 0.05);
  static int aiAttack(int level) => level ~/ 5; // bonus to attack
  static double aiEnergy(int level) => min(1.9, 1 + level * 0.04); // energy regeneration multiplier
  static double aiDeployEvery(int level) => max(2.5, 5.5 - level * 0.15);
  static double aiStartEnergy(int level) => min(9, startEnergy + level * 0.2);
  static int aiStarters(int level) => startingUnits + (level >= 6 ? 1 : 0) + (level >= 12 ? 1 : 0);
}

/// Extra rules of a tower (or of a custom match): they only touch the enemy.
class LiveRules {
  const LiveRules({
    this.enemySpeed = 1.0,
    this.enemyHp = 1.0,
    this.enemyCooldown = 1.0,
    this.enemyTower = 1.0,
    this.enemyBaseHp = 1.0,
  });
  final double enemySpeed, enemyHp, enemyCooldown, enemyTower, enemyBaseHp;

  static const classic = LiveRules();
  static const desert = LiveRules(enemySpeed: 1.3, enemyHp: 0.9, enemyCooldown: 0.9);
  static const fortress = LiveRules(enemySpeed: 0.9, enemyHp: 1.25, enemyTower: 1.6, enemyBaseHp: 1.3);
}

enum LiveFormation { free, line, column, square }

/// One of the four flank villages. Hold it alone for a few seconds to take it.
class LiveTown {
  LiveTown(this.id, this.cell, this.owner);
  final String id;
  final Pos cell;
  Side owner;
  double progressPlayer = 0;
  double progressAi = 0;
  double get x => cell.c + 0.5;
  double get y => cell.r + 0.5;
  double progressOf(Side s) => (s == Side.player ? progressPlayer : progressAi) / LiveTuning.captureSeconds;
}

class LiveBase {
  LiveBase(this.side, this.cell, {double hpMul = 1.0})
      : maxHp = LiveTuning.baseHp * hpMul,
        hp = LiveTuning.baseHp * hpMul;
  final Side side;
  final Pos cell;
  final double maxHp;
  double hp;
  double cooldown = 0;
  double get x => cell.c + 0.5;
  double get y => cell.r + 0.5;
}

/// A card of the deck = one unit you can send to the battlefield.
class LiveCard {
  LiveCard(this.type)
      : cost = type.isHero
            ? (2 + type.rarity).clamp(3, 6).toInt()
            : ((type.hp + type.attack * 1.2) / 3).round().clamp(2, 5).toInt();
  final UnitType type;
  final int cost;
  LiveUnit? unit; // the unit currently on the field
  double readyAt = 0;
}

class LiveHand {
  LiveHand(this.queue) : energy = LiveTuning.startEnergy;
  final List<LiveCard> queue; // the first handSize cards are playable
  double energy;
  List<LiveCard> get hand => queue.take(LiveTuning.handSize).toList();
}

class LiveUnit {
  LiveUnit(this.id, this.type, this.side, this.x, this.y, double hpMul)
      : hp = type.hp * hpMul * LiveTuning.hpMultiplier,
        maxHp = type.hp * hpMul * LiveTuning.hpMultiplier,
        unit = Unit(id, type, side, const Pos(0, 0));

  final int id;
  final UnitType type;
  final Side side;
  final Unit unit; // used only to draw the token
  double x, y;
  double hp;
  final double maxHp;
  double cooldown = 0;
  double? destX, destY;
  Map<Pos, double>? field;
  bool attackMove = false;
  LiveUnit? target; // forced target (attack order)
  LiveCard? card;
  bool hold = false; // "tenir la position": does not move, fights what comes in range
  bool chase = true; // false = never leaves its place/path to pursue an enemy
  LiveUnit? escortOf; // follows this unit and fights near it

  bool get alive => hp > 0;
  bool get hasDest => destX != null;

  bool get isArcher => type.ranged;
  bool get isHero => type.isHero;
  bool get isCavalry =>
      type.id == 'rider' || type.id == 'camel' || type.id == 'scout' || type.role == 'rider';
}

class LiveShot {
  LiveShot(this.ax, this.ay, this.bx, this.by, this.ranged);
  final double ax, ay, bx, by;
  final bool ranged;
  double age = 0;
}

class LiveFx {
  LiveFx(this.x, this.y, this.text, this.good);
  final double x, y;
  final String text;
  final bool good;
  double age = 0;
}

/// Real-time battle: units walk on their own toward ordered points and fight
/// automatically when an enemy is within reach. Pure Dart (no Flutter).
class LiveGame {
  LiveGame({
    required List<UnitType> playerArmy,
    required List<UnitType> enemyArmy,
    GameMap? gameMap,
    int seed = 1,
    this.level = 6,
    this.rules = LiveRules.classic,
  })  : map = gameMap ?? GameMap.rush(extraRows: LiveTuning.extraRows),
        _rng = Random(seed) {
    playerBase = LiveBase(Side.player, map.playerCapital.citadel);
    enemyBase = LiveBase(Side.ai, map.enemyCapital.citadel, hpMul: rules.enemyBaseHp);
    for (final c in map.cities) {
      if (c.capitalOf != null) continue;
      towns.add(LiveTown(c.id, c.citadel, c.citadel.r < map.rows / 2 ? Side.ai : Side.player));
    }
    for (final side in Side.values) {
      final army = side == Side.player ? playerArmy : enemyArmy;
      final cards = [for (final t in army) LiveCard(t)];
      hands[side] = LiveHand(cards);
      if (side == Side.ai) hands[side]!.energy = LiveTuning.aiStartEnergy(level);
      _placeStarters(side);
    }
  }

  final GameMap map;
  final int level; // AI difficulty
  final LiveRules rules;
  late final LiveBase playerBase;
  late final LiveBase enemyBase;
  final List<LiveTown> towns = [];
  final Random _rng;
  final Map<Side, LiveHand> hands = {};
  final List<LiveUnit> units = [];
  double _aiDeployClock = 0;
  double _aiThinkClock = 0;
  final List<LiveShot> shots = [];
  final List<LiveFx> fx = [];
  final Map<String, Map<Pos, double>> _fields = {};
  double time = 0;
  Side? winner;
  String endReason = '';
  int _nextId = 1;

  static const List<(int, int)> _dirs = [
    (1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1),
  ];

  bool get over => winner != null;
  Iterable<LiveUnit> get alive => units.where((u) => u.alive);
  Iterable<LiveUnit> aliveOf(Side s) => units.where((u) => u.alive && u.side == s);
  LiveBase baseOf(Side s) => s == Side.player ? playerBase : enemyBase;
  Side _other(Side s) => s == Side.player ? Side.ai : Side.player;
  int townsOf(Side s) => towns.where((t) => t.owner == s).length;

  // ------------------------------------------------------------ setup

  bool get preparing => time < LiveTuning.prepSeconds;
  double get midY => map.rows / 2;

  /// Natural territory: your half of the field, behind the river.
  bool inZone(Side side, double y) => side == Side.player ? y >= midY + 2.5 : y <= midY - 2.5;

  bool _inTownBox(LiveTown t, double x, double y) =>
      (x - t.x).abs() <= LiveTuning.townZoneHalf && (y - t.y).abs() <= LiveTuning.townZoneHalf;

  /// Your territory plus the box around every town you hold.
  bool inDeploymentZone(Side side, double x, double y) {
    if (inZone(side, y)) return true;
    return towns.any((t) => t.owner == side && _inTownBox(t, x, y));
  }

  /// The box around a town the opponent holds is closed to you.
  bool enemyDeploymentBlocked(Side side, double x, double y) =>
      towns.any((t) => t.owner != side && _inTownBox(t, x, y));

  bool canDeployAt(Side side, double x, double y) =>
      inDeploymentZone(side, x, y) && !enemyDeploymentBlocked(side, x, y);

  LiveHand handOf(Side s) => hands[s]!;

  /// The first cards are already on the map at different distances from the
  /// front, the others wait in the hand.
  void _placeStarters(Side side) {
    final q = hands[side]!.queue;
    final dir = side == Side.player ? -1 : 1;
    final base = baseOf(side);
    final spots = [
      (3.5, midY - dir * 3.2), // forward, near the river
      (10.0, base.y + dir * 6.0),
      (6.5, base.y + dir * 3.0),
      (10.5, midY - dir * 4.5),
      (2.5, base.y + dir * 7.5),
    ];
    final n = min(side == Side.ai ? LiveTuning.aiStarters(level) : LiveTuning.startingUnits, min(spots.length, q.length));
    for (var i = 0; i < n; i++) {
      final u = _spawnCard(side, q[i], spots[i].$1, spots[i].$2);
      if (side == Side.ai) _aiAssign(u);
    }
    // played cards go to the back of the queue
    for (var i = 0; i < n; i++) {
      q.add(q.removeAt(0));
    }
  }

  LiveUnit _spawnCard(Side side, LiveCard card, double x, double y) {
    final p = _nearestPassable(x, y, card.type.noMountain);
    final mul = side == Side.ai ? LiveTuning.aiHp(level) * rules.enemyHp : 1.0;
    final u = LiveUnit(_nextId++, card.type, side, p.$1, p.$2, mul);
    u.card = card;
    card.unit = u;
    units.add(u);
    return u;
  }

  bool canPlay(Side side, LiveCard card) {
    if (over) return false;
    final h = handOf(side);
    if (!h.hand.contains(card)) return false;
    if (h.energy < card.cost) return false;
    final u = card.unit;
    if (u != null && u.alive) return false;
    return time >= card.readyAt;
  }

  /// Place [card] at (x, y) inside your own territory. Returns the new unit.
  LiveUnit? play(Side side, LiveCard card, double x, double y) {
    if (!canPlay(side, card) || !canDeployAt(side, x, y)) return null;
    final h = handOf(side);
    h.energy -= card.cost;
    h.queue.remove(card);
    h.queue.add(card);
    final u = _spawnCard(side, card, x, y);
    if (side == Side.ai) _aiAssign(u);
    return u;
  }

  void _energy(double dt) {
    for (final e in hands.entries) {
      final mul = e.key == Side.ai ? LiveTuning.aiEnergy(level) : 1.0;
      e.value.energy = min(LiveTuning.maxEnergy, e.value.energy + dt * LiveTuning.energyPerSecond * mul);
    }
  }

  // --------------------------------------------------------------- AI

  /// Choose what a fresh enemy unit does: raid a town, or march on your base.
  void _aiAssign(LiveUnit u) {
    final foeTowns = towns.where((t) => t.owner != Side.ai).toList();
    if (foeTowns.isNotEmpty && (u.isCavalry || u.type.id == 'skirmisher' || _rng.nextDouble() < 0.3)) {
      foeTowns.sort((a, b) => _distToPoint(u, a.x, a.y).compareTo(_distToPoint(u, b.x, b.y)));
      _setDest(u, foeTowns.first.x, foeTowns.first.y, true);
    } else {
      _setDest(u, playerBase.x, playerBase.y, true);
    }
  }

  void _aiDeploy(double dt) {
    _aiDeployClock += dt;
    if (_aiDeployClock < LiveTuning.aiDeployEvery(level)) return;
    _aiDeployClock = 0;
    final h = handOf(Side.ai);
    final options = h.hand.where((c) => canPlay(Side.ai, c)).toList();
    if (options.isEmpty) return;
    if (level < 3 && h.energy < 8 && _rng.nextDouble() < 0.25) return;

    // pick the card that counters what you fielded
    final foes = aliveOf(Side.player).toList();
    final archers = foes.where((u) => u.isArcher).length;
    final cav = foes.where((u) => u.isCavalry).length;
    final melee = foes.length - archers - cav;
    LiveCard? best;
    var bs = -1e9;
    for (final c in options) {
      final t = c.type;
      final isCav = t.role == 'rider' || t.id == 'rider' || t.id == 'camel' || t.id == 'scout';
      var sc = c.cost.toDouble();
      if (level >= 2) {
        if (archers >= 2 && isCav) sc += 2.5;
        if (cav >= 2 && (t.id == 'spearmen' || t.id == 'guard')) sc += 2.5;
        if (melee >= 3 && t.ranged) sc += 2;
      }
      if (t.isHero) sc += 1;
      sc += _rng.nextDouble();
      if (sc > bs) {
        bs = sc;
        best = c;
      }
    }
    if (best == null) return;

    // where: close to the base when it is threatened, otherwise near the front
    final threatened = foes.any((u) => _distToPoint(u, enemyBase.x, enemyBase.y) <= 8);
    for (var i = 0; i < 14; i++) {
      final x = 1.0 + _rng.nextDouble() * (map.cols - 2);
      final double y;
      if (threatened) {
        y = enemyBase.y + 1.0 + _rng.nextDouble() * 3.5;
      } else if (level >= 3) {
        y = midY - 6.0 + _rng.nextDouble() * 3.4;
      } else {
        y = enemyBase.y + 1.5 + _rng.nextDouble() * 4;
      }
      if (canDeployAt(Side.ai, x, y)) {
        play(Side.ai, best, x, y);
        return;
      }
    }
  }

  /// Once a second: defend the base, send idle units back to work.
  void _aiThink(double dt) {
    _aiThinkClock += dt;
    if (_aiThinkClock < 1.0) return;
    _aiThinkClock = 0;
    final threats = aliveOf(Side.player).where((p) => _distToPoint(p, enemyBase.x, enemyBase.y) <= 8).toList();
    for (final u in aliveOf(Side.ai)) {
      if (u.hold) continue;
      if (level >= 1 && threats.isNotEmpty && _distToPoint(u, enemyBase.x, enemyBase.y) <= 14) {
        threats.sort((a, b) => _dist2(u, a).compareTo(_dist2(u, b)));
        _setDest(u, threats.first.x, threats.first.y, true);
        continue;
      }
      if (!u.hasDest && u.target == null) _aiAssign(u);
    }
  }

  double _dist2(LiveUnit a, LiveUnit b) => (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);

  // ----------------------------------------------------------- terrain

  Pos _cell(LiveUnit u) => Pos(max(0, min(map.cols - 1, u.x.floor())), max(0, min(map.rows - 1, u.y.floor())));

  bool _passable(Pos p, bool noMountain) {
    if (!map.inBounds(p)) return false;
    final t = map.terrainAt(p);
    if (t.impassable) return false;
    if (noMountain && t == Terrain.mountain) return false;
    return true;
  }

  bool _passableXY(double x, double y, LiveUnit u) {
    if (x < 0.05 || y < 0.05 || x > map.cols - 0.05 || y > map.rows - 0.05) return false;
    return _passable(Pos(x.floor(), y.floor()), u.type.noMountain);
  }

  (double, double) _nearestPassable(double x, double y, bool noMountain) {
    final c0 = max(0, min(map.cols - 1, x.floor()));
    final r0 = max(0, min(map.rows - 1, y.floor()));
    if (_passable(Pos(c0, r0), noMountain)) return (c0 + 0.5, r0 + 0.5);
    for (var rad = 1; rad < 12; rad++) {
      for (var dc = -rad; dc <= rad; dc++) {
        for (var dr = -rad; dr <= rad; dr++) {
          if (max(dc.abs(), dr.abs()) != rad) continue;
          final p = Pos(c0 + dc, r0 + dr);
          if (_passable(p, noMountain)) return (p.c + 0.5, p.r + 0.5);
        }
      }
    }
    return (c0 + 0.5, r0 + 0.5);
  }

  // ----------------------------------------------------------- orders

  /// Slots of a formation, front row first. dy grows toward the back.
  List<(double, double)> formationSlots(int n, LiveFormation f) {
    final out = <(double, double)>[];
    if (n <= 0) return out;
    final width = switch (f) {
      LiveFormation.line => min(n, 7),
      LiveFormation.column => n <= 3 ? 1 : 2,
      LiveFormation.square => max(1, sqrt(n).ceil()),
      LiveFormation.free => 1,
    };
    final rows = (n / width).ceil();
    for (var r = 0; r < rows; r++) {
      final cnt = min(width, n - r * width);
      for (var c = 0; c < cnt; c++) {
        out.add(((c - (cnt - 1) / 2) * LiveTuning.formationSpacing, r * LiveTuning.formationSpacing));
      }
    }
    return out;
  }

  /// Send [group] to the point (x, y): each unit walks there by itself.
  /// With a formation, melee units take the front rows and archers stand behind.
  void orderMove(Iterable<LiveUnit> group, double x, double y,
      {bool attackMove = false, LiveFormation formation = LiveFormation.free}) {
    final list = group.where((u) => u.alive && u.side == Side.player).toList();
    if (list.isEmpty) return;
    if (formation == LiveFormation.free || list.length == 1) {
      var i = 0;
      for (final u in list) {
        final ang = i * 2.4;
        final rad = 0.5 * sqrt(i.toDouble());
        final p = _nearestPassable(x + cos(ang) * rad, y + sin(ang) * rad, u.type.noMountain);
        _setDest(u, p.$1, p.$2, attackMove);
        i++;
      }
      return;
    }
    final front = list.where((u) => !u.isArcher).toList()..sort((a, b) => a.x.compareTo(b.x));
    final back = list.where((u) => u.isArcher).toList()..sort((a, b) => a.x.compareTo(b.x));
    final frontSlots = formationSlots(front.length, formation);
    final backSlots = formationSlots(back.length, formation);
    var offset = 0.0;
    for (final s in frontSlots) {
      offset = max(offset, s.$2 + LiveTuning.formationSpacing);
    }
    for (var i = 0; i < front.length; i++) {
      final p = _nearestPassable(x + frontSlots[i].$1, y + frontSlots[i].$2, front[i].type.noMountain);
      _setDest(front[i], p.$1, p.$2, attackMove);
    }
    for (var i = 0; i < back.length; i++) {
      final p = _nearestPassable(x + backSlots[i].$1, y + backSlots[i].$2 + offset, back[i].type.noMountain);
      _setDest(back[i], p.$1, p.$2, attackMove);
    }
  }

  void _setDest(LiveUnit u, double x, double y, bool attackMove) {
    u.destX = x;
    u.destY = y;
    u.attackMove = attackMove;
    u.target = null;
    u.hold = false;
    u.escortOf = null;
    u.field = _field(Pos(x.floor(), y.floor()), u.type.noMountain);
  }

  void _clearOrders(LiveUnit u) {
    u.destX = null;
    u.destY = null;
    u.field = null;
    u.target = null;
    u.escortOf = null;
    u.hold = false;
  }

  void orderAttack(Iterable<LiveUnit> group, LiveUnit enemy) {
    for (final u in group) {
      if (!u.alive || u.side != Side.player) continue;
      _clearOrders(u);
      u.target = enemy;
    }
  }

  /// "Tenir la position": stop, do not pursue, fight what comes in range.
  void orderHold(Iterable<LiveUnit> group) {
    for (final u in group) {
      if (!u.alive || u.side != Side.player) continue;
      _clearOrders(u);
      u.hold = true;
      u.chase = false;
    }
  }

  /// "Escorter": follow [leader] and fight around it.
  void orderEscort(Iterable<LiveUnit> group, LiveUnit leader) {
    for (final u in group) {
      if (!u.alive || u.side != Side.player || u == leader) continue;
      _clearOrders(u);
      u.escortOf = leader;
      u.chase = true;
    }
  }

  /// "Poursuivre" on or off: off = never leave your place or path to chase.
  void setChase(Iterable<LiveUnit> group, bool on) {
    for (final u in group) {
      if (!u.alive || u.side != Side.player) continue;
      u.chase = on;
      if (on) u.hold = false;
    }
  }

  /// Attack-move toward the enemy capital.
  void orderCharge(Iterable<LiveUnit> group, {LiveFormation formation = LiveFormation.free}) {
    orderMove(group, enemyBase.x, enemyBase.y, attackMove: true, formation: formation);
  }

  // ------------------------------------------------------ path fields

  Map<Pos, double> _field(Pos goal, bool noMountain) {
    final key = '${goal.c},${goal.r},$noMountain';
    final cached = _fields[key];
    if (cached != null) return cached;
    final d = <Pos, double>{goal: 0};
    final open = <Pos>[goal];
    final done = <Pos>{};
    while (open.isNotEmpty) {
      var bi = 0;
      for (var i = 1; i < open.length; i++) {
        if (d[open[i]]! < d[open[bi]]!) bi = i;
      }
      final cur = open.removeAt(bi);
      if (!done.add(cur)) continue;
      for (final dir in _dirs) {
        final n = Pos(cur.c + dir.$1, cur.r + dir.$2);
        if (!_passable(n, noMountain)) continue;
        final diag = dir.$1 != 0 && dir.$2 != 0;
        if (diag &&
            (!_passable(Pos(cur.c + dir.$1, cur.r), noMountain) ||
                !_passable(Pos(cur.c, cur.r + dir.$2), noMountain))) {
          continue;
        }
        final nd = d[cur]! + map.terrainAt(n).moveCost * (diag ? 1.41 : 1.0);
        if (nd < (d[n] ?? 1e18)) {
          d[n] = nd;
          open.add(n);
        }
      }
    }
    _fields[key] = d;
    return d;
  }

  // --------------------------------------------------------- movement

  double _speedOf(LiveUnit u) {
    final cost = map.terrainAt(_cell(u)).moveCost;
    final factor = 1 / (1 + (min(cost, 3) - 1) * 0.55);
    final side = u.side == Side.ai ? rules.enemySpeed : 1.0;
    return u.type.move * LiveTuning.speedPerMove * factor * side;
  }

  void _step(LiveUnit u, double gx, double gy, double dt) {
    final dx = gx - u.x, dy = gy - u.y;
    final d = sqrt(dx * dx + dy * dy);
    if (d < 1e-6) return;
    final m = min(_speedOf(u) * dt, d);
    final nx = u.x + dx / d * m, ny = u.y + dy / d * m;
    if (_passableXY(nx, ny, u)) {
      u.x = nx;
      u.y = ny;
    } else if (_passableXY(nx, u.y, u)) {
      u.x = nx;
    } else if (_passableXY(u.x, ny, u)) {
      u.y = ny;
    }
  }

  void _moveAlong(LiveUnit u, Map<Pos, double> field, double tx, double ty, double dt) {
    final cell = _cell(u);
    var best = cell;
    var bv = field[cell] ?? 1e18;
    for (final dir in _dirs) {
      final n = Pos(cell.c + dir.$1, cell.r + dir.$2);
      if (!_passable(n, u.type.noMountain)) continue;
      final diag = dir.$1 != 0 && dir.$2 != 0;
      if (diag &&
          (!_passable(Pos(cell.c + dir.$1, cell.r), u.type.noMountain) ||
              !_passable(Pos(cell.c, cell.r + dir.$2), u.type.noMountain))) {
        continue;
      }
      final v = field[n] ?? 1e18;
      if (v < bv - 1e-9) {
        bv = v;
        best = n;
      }
    }
    if (best == cell) {
      _step(u, tx, ty, dt);
    } else {
      _step(u, best.c + 0.5, best.r + 0.5, dt);
    }
  }

  void _walkTo(LiveUnit u, double x, double y, double dt) {
    final goal = Pos(max(0, min(map.cols - 1, x.floor())), max(0, min(map.rows - 1, y.floor())));
    _moveAlong(u, _field(goal, u.type.noMountain), x, y, dt);
  }

  // ----------------------------------------------------------- combat

  double _rangeOf(LiveUnit u) {
    var r = u.type.maxR + 0.4;
    if (u.type.ranged) {
      r += map.terrainAt(_cell(u)).rangeBonus * 0.5;
    }
    return r;
  }

  double _cooldownOf(LiveUnit u) {
    final base = u.type.ranged
        ? LiveTuning.rangedCooldown
        : (u.isCavalry ? LiveTuning.cavalryCooldown : LiveTuning.meleeCooldown);
    return u.side == Side.ai ? base * rules.enemyCooldown : base;
  }

  double _dist(LiveUnit a, LiveUnit b) => sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)).toDouble();

  double _distToPoint(LiveUnit u, double x, double y) => sqrt(pow(u.x - x, 2) + pow(u.y - y, 2)).toDouble();

  void _strike(LiveUnit a, LiveUnit t) {
    final d = _dist(a, t);
    var atk = a.type.attack + (d <= 1.7 ? a.type.meleeBonus : 0);
    if (a.side == Side.ai) atk += LiveTuning.aiAttack(level);
    final def = t.type.defense + map.terrainAt(_cell(t)).defense;
    final dmg = max(LiveTuning.minDamage, (atk - def) * LiveTuning.damageScale);
    t.hp -= dmg;
    a.cooldown = _cooldownOf(a);
    shots.add(LiveShot(a.x, a.y, t.x, t.y, a.type.ranged));
    fx.add(LiveFx(t.x, t.y - 0.3, '-${dmg.toStringAsFixed(dmg < 10 ? 1 : 0)}', false));
  }

  void _strikeBase(LiveUnit a, LiveBase b) {
    final dmg = max(LiveTuning.minDamage, a.type.attack * LiveTuning.baseDamageScale);
    b.hp -= dmg;
    a.cooldown = _cooldownOf(a);
    shots.add(LiveShot(a.x, a.y, b.x, b.y, a.type.ranged));
    fx.add(LiveFx(b.x, b.y - 0.4, '-${dmg.toStringAsFixed(1)}', false));
  }

  // ------------------------------------------------------------- tick

  void tick(double dt) {
    if (over) return;
    time += dt;
    _energy(dt);
    _aiDeploy(dt);
    if (preparing) {
      _age(dt);
      return;
    }
    _aiThink(dt);

    for (final u in units) {
      if (!u.alive) continue;
      u.cooldown -= dt;
      if (u.type.healer) {
        for (final o in aliveOf(u.side)) {
          if (o != u && _dist(u, o) <= 1.6 && o.hp < o.maxHp) o.hp = min(o.maxHp, o.hp + 0.6 * dt);
        }
      }
      if (u.type.regen > 0) u.hp = min(u.maxHp, u.hp + u.type.regen * 0.3 * dt);

      final range = _rangeOf(u);
      LiveUnit? tgt = u.target;
      if (tgt != null && !tgt.alive) {
        u.target = null;
        tgt = null;
      }
      final leader = u.escortOf;
      if (leader != null && !leader.alive) u.escortOf = null;

      LiveUnit? nearest; // closest enemy
      var nd = 1e9;
      LiveUnit? weakest; // weakest enemy in range: focus fire
      var wh = 1e9;
      for (final f in aliveOf(_other(u.side))) {
        final d = _dist(u, f);
        if (d < nd) {
          nd = d;
          nearest = f;
        }
        if (d <= range && f.hp < wh) {
          wh = f.hp;
          weakest = f;
        }
      }

      // attack whatever is in range
      if (u.cooldown <= 0 && u.type.attack > 0) {
        LiveUnit? hit;
        if (tgt != null && _dist(u, tgt) <= range) {
          hit = tgt;
        } else {
          hit = weakest;
        }
        if (hit != null) {
          _strike(u, hit);
        } else {
          final eb = baseOf(_other(u.side));
          final bd = sqrt(pow(u.x - eb.x, 2) + pow(u.y - eb.y, 2));
          if (bd <= range + 0.3) _strikeBase(u, eb);
        }
      }

      // movement
      final aggro = range + LiveTuning.aggroExtra;
      final kite = u.side == Side.ai && level >= 3 && u.isArcher && nearest != null && nd < 1.7;
      if (kite) {
        final en = nearest!;
        _step(u, u.x + (u.x - en.x) * 2, u.y + (u.y - en.y) * 2, dt);
      } else if (tgt != null) {
        if (_dist(u, tgt) > range * 0.92) _walkTo(u, tgt.x, tgt.y, dt);
      } else if (u.escortOf != null) {
        final l = u.escortOf!;
        final en = nearest;
        final enemyNearLeader = en != null &&
            nd <= aggro &&
            sqrt(pow(en.x - l.x, 2) + pow(en.y - l.y, 2)) <= 3.5;
        if (u.chase && enemyNearLeader) {
          if (nd > range * 0.92) _walkTo(u, en!.x, en.y, dt);
        } else if (_dist(u, l) > 1.9) {
          _walkTo(u, l.x, l.y, dt);
        }
      } else if (u.hold) {
        // stays where it is
      } else {
        final engage = u.chase && nearest != null && nd <= aggro && (!u.hasDest || u.attackMove);
        if (engage) {
          if (nd > range * 0.92) {
            final en = nearest!;
            _walkTo(u, en.x, en.y, dt);
          }
        } else if (u.hasDest) {
          final dx = u.destX! - u.x, dy = u.destY! - u.y;
          final dd = sqrt(dx * dx + dy * dy);
          var arrived = dd < 0.35;
          if (!arrived && dd < 1.8) {
            arrived = aliveOf(u.side).any((o) => o != u && !o.hasDest && sqrt(pow(o.x - u.x, 2) + pow(o.y - u.y, 2)) < 0.6);
          }
          if (arrived) {
            u.destX = null;
            u.destY = null;
            u.field = null;
          } else if (u.field != null) {
            _moveAlong(u, u.field!, u.destX!, u.destY!, dt);
          }
        }
      }
    }

    _separate(dt);
    _captureTowns(dt);
    _towers(dt);

    for (final u in units) {
      u.unit.hp = max(1, u.hp.ceil());
    }
    units.removeWhere((u) {
      if (u.alive) return false;
      for (final o in units) {
        if (o.target == u) o.target = null;
        if (o.escortOf == u) o.escortOf = null;
      }
      final c = u.card;
      if (c != null) {
        c.unit = null;
        c.readyAt = time + LiveTuning.cardCooldown;
      }
      return true;
    });
    _age(dt);
    _checkEnd();
  }

  void _age(double dt) {
    for (final s in shots) {
      s.age += dt;
    }
    shots.removeWhere((s) => s.age > 0.25);
    for (final f in fx) {
      f.age += dt;
    }
    fx.removeWhere((f) => f.age > 0.8);
  }

  void _separate(double dt) {
    const minD = 0.55;
    final list = units.where((u) => u.alive).toList();
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i], b = list[j];
        final dx = b.x - a.x, dy = b.y - a.y;
        final d = sqrt(dx * dx + dy * dy);
        if (d >= minD) continue;
        final ux = d < 1e-4 ? 1.0 : dx / d;
        final uy = d < 1e-4 ? 0.0 : dy / d;
        final push = (minD - d) / 2 * min(1.0, dt * 10);
        if (_passableXY(a.x - ux * push, a.y - uy * push, a)) {
          a.x -= ux * push;
          a.y -= uy * push;
        }
        if (_passableXY(b.x + ux * push, b.y + uy * push, b)) {
          b.x += ux * push;
          b.y += uy * push;
        }
      }
    }
  }

  /// A town changes hands when one side stays alone near it long enough.
  void _captureTowns(double dt) {
    for (final town in towns) {
      final nearPlayer = aliveOf(Side.player).where((u) => _distToPoint(u, town.x, town.y) <= LiveTuning.townRadius).length;
      final nearAi = aliveOf(Side.ai).where((u) => _distToPoint(u, town.x, town.y) <= LiveTuning.townRadius).length;
      if (nearPlayer > 0 && nearAi == 0) {
        town.progressAi = max(0, town.progressAi - dt);
        if (town.owner != Side.player) {
          town.progressPlayer = min(LiveTuning.captureSeconds, town.progressPlayer + dt * min(2, nearPlayer));
          if (town.progressPlayer >= LiveTuning.captureSeconds) {
            town.owner = Side.player;
            town.progressPlayer = 0;
            fx.add(LiveFx(town.x, town.y - 0.8, '★', true));
          }
        }
      } else if (nearAi > 0 && nearPlayer == 0) {
        town.progressPlayer = max(0, town.progressPlayer - dt);
        if (town.owner != Side.ai) {
          town.progressAi = min(LiveTuning.captureSeconds, town.progressAi + dt * min(2, nearAi));
          if (town.progressAi >= LiveTuning.captureSeconds) {
            town.owner = Side.ai;
            town.progressAi = 0;
            fx.add(LiveFx(town.x, town.y - 0.8, '★', false));
          }
        }
      } else {
        town.progressPlayer = max(0, town.progressPlayer - dt * 0.25);
        town.progressAi = max(0, town.progressAi - dt * 0.25);
      }
    }
  }

  void _towers(double dt) {
    for (final b in [playerBase, enemyBase]) {
      b.cooldown -= dt;
      if (b.cooldown > 0 || b.hp <= 0) continue;
      LiveUnit? best;
      var bd = LiveTuning.baseTowerRange;
      for (final u in aliveOf(_other(b.side))) {
        final d = sqrt(pow(u.x - b.x, 2) + pow(u.y - b.y, 2));
        if (d < bd) {
          bd = d;
          best = u;
        }
      }
      if (best != null) {
        final dmg = LiveTuning.baseTowerDamage * (b.side == Side.ai ? rules.enemyTower : 1.0);
        best.hp -= dmg;
        b.cooldown = LiveTuning.baseTowerCooldown;
        shots.add(LiveShot(b.x, b.y, best.x, best.y, true));
        fx.add(LiveFx(best.x, best.y - 0.3, '-${dmg.toStringAsFixed(1)}', false));
      }
    }
  }

  void _checkEnd() {
    if (enemyBase.hp <= 0) {
      winner = Side.player;
      endReason = 'base';
    } else if (playerBase.hp <= 0) {
      winner = Side.ai;
      endReason = 'base';
    } else if (time >= LiveTuning.prepSeconds + LiveTuning.battleSeconds) {
      final mineHp = playerBase.hp / playerBase.maxHp;
      final theirHp = enemyBase.hp / enemyBase.maxHp;
      if ((mineHp - theirHp).abs() > 0.004) {
        winner = mineHp > theirHp ? Side.player : Side.ai;
      } else if (townsOf(Side.player) != townsOf(Side.ai)) {
        winner = townsOf(Side.player) > townsOf(Side.ai) ? Side.player : Side.ai;
      } else {
        final mine = aliveOf(Side.player).fold<double>(0, (a, u) => a + u.hp);
        final theirs = aliveOf(Side.ai).fold<double>(0, (a, u) => a + u.hp);
        winner = mine >= theirs ? Side.player : Side.ai;
      }
      endReason = 'time';
    }
  }
}
