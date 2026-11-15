import 'dart:math';

import '../models/battlefield.dart';
import '../models/game_map.dart';
import '../models/cards.dart';
import '../models/side.dart';
import '../models/story.dart';
import '../models/terrain.dart';
import '../models/units.dart';
import '../strings.dart';

enum Phase { deploy, battle }

/// conquest: big Middle-East map. rush: small fast 1v1 map. messenger: escort.
enum GameMode { conquest, rush, messenger, story }

/// Small visual event (floating number) for the UI.
class FxEvent {
  const FxEvent(this.pos, this.text, this.kind);
  final Pos pos;
  final String text;
  final int kind; // 0 damage, 1 heal, 2 info
}

class PlayerState {
  PlayerState(this.side, List<CardDef> deck, this.roster)
      : drawPile = List.of(deck);

  final Side side;
  final List<CardDef> drawPile;
  final List<CardDef> hand = [];
  final List<CardDef> discard = [];

  /// Units still to be placed (deployment phase).
  final List<UnitType> roster;
  final List<UnitType> fallen = [];
  int energy = 0;
  int objectiveProgress = 0;
}

class _Reveal {
  _Reveal(this.pos, this.side);
  final Pos pos;
  final Side side;
}

class _Undo {
  _Undo(this.unit, this.from);
  final Unit unit;
  final Pos from;
}

/// Pure Dart rules. Action methods return an error message (String) when the
/// action is refused, or null on success. A refused action changes nothing.
class Game {
  Game({
    required DeckDef playerDeck,
    required DeckDef aiDeck,
    this.mode = GameMode.conquest,
    int seed = 1,
    GameMap? gameMap,
    this.chapter,
    this.aiBoost = 0,
  })  : rng = Random(seed),
        map = gameMap ?? (mode == GameMode.rush ? GameMap.rush() : GameMap.generate(seed)) {
    final playerArmy = playerDeck.army();
    if (mode == GameMode.messenger) playerArmy.add(unitById['messenger']!);
    players[Side.player] = PlayerState(Side.player, playerDeck.build(), playerArmy);
    players[Side.ai] = PlayerState(Side.ai, aiDeck.build(), aiDeck.army());
    for (final p in players.values) {
      p.drawPile.shuffle(rng);
      for (var i = 0; i < openingHand; i++) {
        _draw(p);
      }
    }
    for (final c in map.cities) {
      cityOwner[c] = c.capitalOf;
    }
    final start = chapter;
    if (start != null && start.enemyStart.isNotEmpty) {
      _placeStart(Side.ai, start.enemyStart);
    } else {
      autoPlace(Side.ai);
    }
    if (start != null && start.playerStart.isNotEmpty) {
      _placeStart(Side.player, start.playerStart);
    }
    _placeGarrisons();
    _log('log_start');
  }

  static const int maxRounds = 60;
  static const int handLimit = 5;
  static const int baseEnergy = 3;
  static const int captureTurns = 2;
  static const int openingHand = 3;
  static const int maxTroop = 4;

  final GameMode mode;
  final StoryChapter? chapter; // story mode only
  final GameMap map;
  final Map<Pos, Map<Pos, int>> distCache = {}; // AI path distances
  final Random rng;
  final List<Unit> units = [];
  final Map<Side, PlayerState> players = {};
  final Map<City, Side?> cityOwner = {};
  final List<String> log = [];
  final List<FxEvent> events = [];
  final List<_Reveal> _reveals = [];
  final List<_Undo> _lastMoves = [];
  final Map<Side, Set<Pos>> _vis = {};
  final List<StoryBeat> storyQueue = []; // dialogues waiting to be shown
  /// Tower mode: strength bonus of the AI army (floor - 1).
  final int aiBoost;

  final Set<String> _fired = {};

  /// Story: while true the AI army flees toward its own capital.
  bool rout = false;
  int _p2Round = 0; // round when the Uhud pursuit ended (0 = not yet)
  bool get uhudPhase2 => _p2Round > 0;
  bool _guardLifted = false; // Uhud: Khalid's protection ended
  final Set<String> _defeated = {}; // unit ids of fallen named figures
  // Badr V2 campaign state: control must be maintained, not merely touched.
  final Set<int> _badrReserveUnitIds = {};
  int _badrWellHoldTurns = 0;
  final Map<Pos, Side> _terr = {};
  bool _terrDirty = true;

  Phase phase = Phase.deploy;
  Side current = Side.player;
  int round = 1;
  int sandstorm = 0;
  Side? winner;
  bool isDraw = false;
  String endReason = '';
  int _nextId = 1;

  // ------------------------------------------------------------ queries

  bool get over => winner != null || isDraw;
  int get roundLimit => switch (mode) {
        GameMode.rush => 25,
        GameMode.story => chapter?.roundLimit ?? 25,
        _ => maxRounds,
      };

  /// Extra movement: conquest is faster, and the first rounds even more so.
  int get speedBonus => switch (mode) {
        GameMode.conquest => 2 + (round <= 6 ? 2 : 0),
        GameMode.messenger => 1,
        GameMode.story => 1,
        GameMode.rush => 0,
      };
  PlayerState get me => players[current]!;
  bool get canUndo => _lastMoves.isNotEmpty && !over && phase == Phase.battle;

  String sideName(Side s) => tr(s == Side.player ? 'side_player' : 'side_ai');

  Unit? unitAt(Pos p) {
    for (final u in units) {
      if (u.pos == p) return u;
    }
    return null;
  }

  Iterable<Unit> unitsOf(Side s) => units.where((u) => u.side == s);

  int totalHp(Side s) => unitsOf(s).fold(0, (sum, u) => sum + u.hp);

  int ownedCities(Side s) => cityOwner.values.where((o) => o == s).length;

  bool holdsOasis(Side s) =>
      unitsOf(s).any((u) => map.terrainAt(u.pos) == Terrain.oasis);

  bool hasForces(Side s) {
    final p = players[s]!;
    bool reinforce(CardDef c) => c.effect == CardEffect.reinforce;
    return unitsOf(s).any((u) => !u.garrison) ||
        p.hand.any(reinforce) ||
        p.drawPile.any(reinforce) ||
        p.discard.any(reinforce);
  }

  /// Enemy units next to the citadel [attacker] wants to take contest it.
  bool objectiveContested(Side attacker) => unitsOf(attacker.other)
      .any((e) => e.pos.dist(map.capitalOf(attacker.other)) <= 1);

  // ---------------------------------------------------------- territory

  static const int claimRadius = 2;

  void _invalidate() {
    _vis.clear();
    _terrDirty = true;
  }

  /// Conquered cells (blue for the player, red for the enemy). A unit (or an
  /// owned city) claims the cells around it; a side keeps a cell only while
  /// it still sees it: when the fog of war comes back, the cell is lost.
  Map<Pos, Side> get territory {
    if (_terrDirty) _syncTerritory();
    return _terr;
  }

  void _syncTerritory() {
    _terrDirty = false;
    // 1. fog is back on a cell -> its owner loses it
    _terr.removeWhere((p, s) => !visibleTo(s).contains(p));
    // 2. units and owned cities claim the cells around them
    void claim(Side s, Pos c, int r, {bool force = false}) {
      final seen = visibleTo(s);
      for (var dy = -r; dy <= r; dy++) {
        final rem = r - dy.abs();
        for (var dx = -rem; dx <= rem; dx++) {
          final p = Pos(c.c + dx, c.r + dy);
          if (!map.inBounds(p) || map.terrainAt(p).impassable) continue;
          if (!seen.contains(p)) continue;
          if (!force && _terr[p] != s) {
            // an enemy unit right next to the cell contests it
            final contested = unitsOf(s.other).any((e) => e.pos.dist(p) <= 1);
            if (contested) continue;
          }
          _terr[p] = s;
        }
      }
    }

    for (final city in cityOwner.keys) {
      final o = cityOwner[city];
      if (o != null) claim(o, city.citadel, claimRadius);
    }
    for (final u in units) {
      claim(u.side, u.pos, claimRadius);
      claim(u.side, u.pos, 0, force: true); // the cell under a unit is always its
    }
  }

  // ---------------------------------------------------------------- fog

  int visionOf(Unit u) {
    final t = map.terrainAt(u.pos);
    var v = u.type.vision + (t == Terrain.hills ? 1 : (t == Terrain.mountain ? 2 : 0));
    if (sandstorm > 0) v = max(1, v - 2);
    return v;
  }

  Set<Pos> visibleTo(Side s) {
    final cached = _vis[s];
    if (cached != null) return cached;
    final res = <Pos>{};
    void reveal(Pos c, int r) {
      for (var dy = -r; dy <= r; dy++) {
        final rem = r - dy.abs();
        for (var dx = -rem; dx <= rem; dx++) {
          final p = Pos(c.c + dx, c.r + dy);
          if (map.inBounds(p)) res.add(p);
        }
      }
    }

    for (final u in units) {
      if (u.side == s) reveal(u.pos, visionOf(u));
    }
    cityOwner.forEach((city, o) {
      if (o == s) reveal(city.citadel, 4);
    });
    for (final rv in _reveals) {
      if (rv.side == s) reveal(rv.pos, 3);
    }
    if (phase == Phase.deploy) {
      for (var r = 0; r < map.rows; r++) {
        for (var c = 0; c < map.cols; c++) {
          if (map.zoneOf(Pos(c, r)) == s) res.add(Pos(c, r));
        }
      }
    }
    _vis[s] = res;
    return res;
  }

  /// Can side [s] see unit [u]? (fog of war, hidden ambushers)
  bool canSee(Side s, Unit u) {
    if (u.side == s) return true;
    if (!visibleTo(s).contains(u.pos)) return false;
    if (u.ambush) return unitsOf(s).any((v) => v.pos.dist(u.pos) <= 1);
    return true;
  }

  // -------------------------------------------------------- combat rules

  int _rangeBonus(Unit u, Pos at) {
    if (!u.type.ranged) return 0;
    return map.terrainAt(at).rangeBonus + u.type.rangeBonus - (sandstorm > 0 ? 1 : 0);
  }

  /// Could [a], standing on [from], hit a unit standing on [to]?
  bool canHit(Unit a, Pos from, Pos to) =>
      a.type.canHit(to.c - from.c, to.r - from.r, bonus: _rangeBonus(a, from));

  int attackPower(Unit u) {
    var a = u.type.attack + u.tempAtk - u.weak;
    if (u.side == Side.ai && u.type.attack > 0) a += min(4, aiBoost ~/ 5);
    if (map.terrainAt(u.pos) == Terrain.dunes && !u.type.duneRider) a -= 1;
    if (unitsOf(u.side).any((o) => o != u && o.type.aura && o.pos.dist(u.pos) <= 1)) {
      a += 1;
    }
    return max(a, u.type.attack == 0 ? 0 : 1);
  }

  int defenseOf(Unit u) {
    var d = u.type.defense + u.bonusDef + u.tempDef + map.terrainAt(u.pos).defense;
    if (u.side == Side.ai) d += min(2, aiBoost ~/ 8);
    if (u.type.troopRole == 'guard' && map.terrainAt(u.pos) == Terrain.fort) d += 1;
    if (unitsOf(u.side).any((o) => o != u && o.type.defenseAura && o.pos.dist(u.pos) <= 1)) d += 1;
    return max(0, d);
  }

  bool _flanked(Unit a, Unit t) {
    final dx = t.pos.c - a.pos.c;
    final dy = t.pos.r - a.pos.r;
    if (max(dx.abs(), dy.abs()) != 1) return false;
    final o = unitAt(Pos(t.pos.c + dx, t.pos.r + dy));
    return o != null && o.side == a.side && o != a;
  }

  bool _adjacent(Pos a, Pos b) => max((a.c - b.c).abs(), (a.r - b.r).abs()) == 1;

  int previewDamage(Unit a, Unit t) =>
      max(1, attackPower(a) + (_adjacent(a.pos, t.pos) ? a.type.meleeBonus : 0) - defenseOf(t)) +
      (_flanked(a, t) ? 1 + a.type.flankBonus : 0) +
      (a.ambush ? 2 : 0);

  /// Enemy units [a] can hit right now (visible and inside its pattern).
  List<Unit> attackTargets(Unit a) {
    if (a.type.shape == AtkShape.none) return [];
    return units
        .where((t) =>
            t.side != a.side &&
            !isGuarded(t) &&
            canSee(a.side, t) &&
            canHit(a, a.pos, t.pos))
        .toList();
  }

  /// Cells the enemy of [viewer] (visible units) could hit next turn.
  Set<Pos> dangerZone(Side viewer) {
    final res = <Pos>{};
    final foes = units.where((u) =>
        u.side != viewer && canSee(viewer, u) && u.type.shape != AtkShape.none);
    for (final e in foes) {
      final cells = reachable(e).keys.toList()..add(e.pos);
      for (final p in cells) {
        final bonus = _rangeBonus(e, p);
        for (var dy = -6; dy <= 6; dy++) {
          for (var dx = -6; dx <= 6; dx++) {
            if (e.type.canHit(dx, dy, bonus: bonus)) {
              final q = Pos(p.c + dx, p.r + dy);
              if (map.inBounds(q)) res.add(q);
            }
          }
        }
      }
    }
    return res;
  }

  // ------------------------------------------------------------ movement

  int moveBudget(Unit u) => max(1, u.type.move + speedBonus - u.slow);

  /// Cost for [u] to enter [p]; null if it can never enter.
  int? enterCost(Unit u, Pos p) {
    final t = map.terrainAt(p);
    if (t.impassable) return null;
    if (t == Terrain.mountain && u.type.noMountain) return null;
    if (map.roads.contains(p)) return 1;
    if (t == Terrain.dunes && u.type.duneRider) return 1;
    return t.moveCost;
  }

  /// Extra movement for a troop moving as one: 2 units +1, 3-4 units +2.
  int troopBonus(int size) => size <= 1 ? 0 : (size >= 3 ? 2 : 1);

  Map<Pos, int> reachable(Unit u, {Set<Unit> ignore = const {}, int extra = 0}) {
    final budget = moveBudget(u) + extra;
    final best = <Pos, int>{u.pos: 0};
    final open = <Pos>[u.pos];
    while (open.isNotEmpty) {
      open.sort((a, b) => best[a]!.compareTo(best[b]!));
      final cur = open.removeAt(0);
      final cost = best[cur]!;
      for (final n in cur.neighbors) {
        if (!map.inBounds(n)) continue;
        final ec = enterCost(u, n);
        if (ec == null) continue;
        final occ = unitAt(n);
        if (occ != null && !ignore.contains(occ)) continue;
        final nc = cost + ec;
        if (nc > budget) continue;
        final known = best[n];
        if (known == null || nc < known) {
          best[n] = nc;
          open.add(n);
        }
      }
    }
    best.remove(u.pos);
    return best;
  }

  /// Why [m] cannot stand on [to]; null when the cell is free for it.
  String? blockReason(Unit m, Pos to, Set<Unit> ignore) {
    if (!map.inBounds(to)) return tr('why_map');
    final t = map.terrainAt(to);
    if (t.impassable) return tr('why_terrain', {'terrain': t.label});
    if (t == Terrain.mountain && m.type.noMountain) {
      return tr('why_terrain', {'terrain': t.label});
    }
    final occ = unitAt(to);
    if (occ != null && !ignore.contains(occ)) {
      return tr('why_unit', {'name': occ.label});
    }
    return null;
  }

  /// Same-type allies touching [u] (4-neighbours), at most [maxTroop].
  List<Unit> troopOf(Unit u) {
    final res = <Unit>[u];
    var i = 0;
    while (i < res.length && res.length < maxTroop) {
      for (final n in res[i].pos.neighbors) {
        final o = unitAt(n);
        if (o != null &&
            o.side == u.side &&
            o.type.troopRole == u.type.troopRole &&
            !res.contains(o) &&
            res.length < maxTroop) {
          res.add(o);
        }
      }
      i++;
    }
    return res;
  }

  /// Error (with the reason) if the whole troop cannot shift so that
  /// [leader] ends on [dest]; null if the move is valid.
  String? troopMoveError(Unit leader, Pos dest) {
    final troop = troopOf(leader);
    final dx = dest.c - leader.pos.c;
    final dy = dest.r - leader.pos.r;
    if (dx == 0 && dy == 0) return tr('err_unreach');
    final ignore = troop.toSet();
    final bonus = troopBonus(troop.length);
    for (final m in troop) {
      if (m.moved) return tr('err_troop_moved', {'name': m.label});
      final to = Pos(m.pos.c + dx, m.pos.r + dy);
      final why = blockReason(m, to, ignore);
      if (why != null) {
        return tr('err_troop_blocked', {'name': m.label, 'pos': map.inBounds(to) ? to.label : '-', 'why': why});
      }
      if (!reachable(m, ignore: ignore, extra: bonus).containsKey(to)) {
        return tr('err_troop_far', {'name': m.label});
      }
    }
    return null;
  }

  /// Cells where the leader can lead its whole troop.
  Set<Pos> troopDestinations(Unit leader) {
    final troop = troopOf(leader);
    return {
      for (final p in reachable(leader,
              ignore: troop.toSet(), extra: troopBonus(troop.length))
          .keys)
        if (troopMoveError(leader, p) == null) p
    };
  }

  // ------------------------------------------------------- deployment

  Set<Pos> deployCells(Side s) {
    final res = <Pos>{};
    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        final p = Pos(c, r);
        final t = map.terrainAt(p);
        if (map.zoneOf(p) == s && !t.impassable && t != Terrain.mountain && unitAt(p) == null) {
          res.add(p);
        }
      }
    }
    return res;
  }

  Unit spawn(UnitType t, Side side, Pos pos, {bool ready = true}) {
    final u = Unit(_nextId++, t, side, pos);
    if (side == Side.ai && aiBoost > 0) {
      u.hpBonus = min(6, aiBoost ~/ 2);
      u.hp += u.hpBonus;
    }
    if (!ready) {
      u.moved = true;
      u.attacked = true;
    }
    units.add(u);
    _invalidate();
    return u;
  }

  String? placeUnit(UnitType t, Pos p) {
    if (phase != Phase.deploy) return tr('err_phase');
    final pl = players[Side.player]!;
    if (!pl.roster.contains(t)) return tr('err_roster');
    if (!deployCells(Side.player).contains(p)) return tr('err_zone');
    pl.roster.remove(t);
    spawn(t, Side.player, p);
    _log('log_place', {'name': t.name, 'pos': p});
    return null;
  }

  /// Takes a placed unit back to the tray (deployment phase only).
  String? pickUp(Unit u) {
    if (phase != Phase.deploy) return tr('err_phase');
    if (u.side != Side.player) return tr('err_notmine');
    units.remove(u);
    players[Side.player]!.roster.add(u.type);
    _invalidate();
    return null;
  }

  /// Places every unit still in the roster of [s] around its capital,
  /// strong melee units in front (towards the enemy), ranged units behind.
  void autoPlace(Side s) {
    final pl = players[s]!;
    const order = [
      'guard', 'spearmen', 'swordsman', 'camel', 'rider', 'standard',
      'scout', 'healer', 'skirmisher', 'archer', 'messenger',
    ];
    pl.roster.sort((a, b) =>
        order.indexOf(a.troopRole).compareTo(order.indexOf(b.troopRole)));
    final foeCap = map.capitalOf(s.other);
    final spots = deployCells(s).toList()
      ..sort((a, b) {
        final byDist = a.dist(foeCap).compareTo(b.dist(foeCap));
        return byDist != 0 ? byDist : a.c.compareTo(b.c);
      });
    var i = 0;
    while (pl.roster.isNotEmpty && i < spots.length) {
      spawn(pl.roster.removeAt(0), s, spots[i]);
      i++;
    }
  }

  String? beginBattle() {
    if (phase != Phase.deploy) return tr('err_phase');
    final left = players[Side.player]!.roster.length;
    if (left > 0) return tr('err_unplaced', {'n': left});
    phase = Phase.battle;
    _log('log_battle');
    // Queue the chapter opening before round-one events so the story reads
    // in narrative order on the first turn.
    _fire('start');
    startTurn(Side.player);
    return null;
  }

  // ------------------------------------------------------------- actions

  String? _battleErr(Unit? u) {
    if (over) return tr('err_over');
    if (phase != Phase.battle) return tr('err_phase');
    if (u != null && u.side != current) return tr('err_notmine');
    return null;
  }

  String? move(Unit u, Pos to) {
    final e = _battleErr(u);
    if (e != null) return e;
    if (u.moved) return tr('err_moved');
    if (!reachable(u).containsKey(to)) return tr('err_unreach');
    final from = u.pos;
    u.pos = to;
    u.moved = true;
    _lastMoves
      ..clear()
      ..add(_Undo(u, from));
    _log('log_move', {'name': u.label, 'pos': to});
    _afterMove([u]);
    return null;
  }

  String? moveTroop(Unit leader, Pos dest) {
    final e = _battleErr(leader);
    if (e != null) return e;
    final err = troopMoveError(leader, dest);
    if (err != null) return err;
    final troop = troopOf(leader);
    final dx = dest.c - leader.pos.c;
    final dy = dest.r - leader.pos.r;
    _lastMoves.clear();
    final targets = [for (final m in troop) Pos(m.pos.c + dx, m.pos.r + dy)];
    for (var i = 0; i < troop.length; i++) {
      _lastMoves.add(_Undo(troop[i], troop[i].pos));
      troop[i].pos = targets[i];
      troop[i].moved = true;
    }
    _log('log_troop', {'name': leader.name, 'n': troop.length, 'pos': dest});
    _afterMove(troop);
    return null;
  }

  void _afterMove(List<Unit> moved) {
    final ch = chapter;
    if (ch != null) {
      if (moved.any((u) => u.side == Side.player && u.pos == ch.keyWell)) _fire('well');
      if (!_guardLifted &&
          ch.liftCells.isNotEmpty &&
          moved.any((u) => u.side == Side.player && ch.liftCells.contains(u.pos))) {
        _guardLifted = true;
        _fire('guard_lifted');
      }
      if (_p2Round == 0 &&
          ch.bootyCells.isNotEmpty &&
          moved.any((u) => u.side == Side.player && ch.bootyCells.contains(u.pos))) {
        _uhudPhase2(late: false);
      }
      _checkContact();
    }
    for (final u in moved) {
      if (mode == GameMode.messenger &&
          u.type.id == 'messenger' &&
          u.side == Side.player &&
          map.cityAt(u.pos) == map.messageCity) {
        _win(Side.player, tr('reason_delivered'));
      }
    }
  }

  String? undoMove() {
    if (!canUndo) return tr('err_undo');
    for (final m in _lastMoves) {
      m.unit.pos = m.from;
      m.unit.moved = false;
    }
    _lastMoves.clear();
    _log('log_undo');
    return null;
  }

  String? attack(Unit a, Unit t) {
    final e = _battleErr(a);
    if (e != null) return e;
    if (a.attacked) return tr('err_attacked');
    if (a.type.shape == AtkShape.none) return tr('err_noattack', {'name': a.label});
    if (t.side == a.side) return tr('err_friendly');
    if (!canSee(a.side, t)) return tr('err_unseen');
    if (isGuarded(t)) return tr('err_guarded');
    if (!canHit(a, a.pos, t.pos)) return tr('err_pattern', {'name': a.label});
    a.attacked = true;
    t.hold = false; // an attacked unit fights back
    t.guarded = false;
    _lastMoves.clear();
    _strike(a, t);
    if (units.contains(t) &&
        units.contains(a) &&
        t.type.shape != AtkShape.none &&
        canHit(t, t.pos, a.pos)) {
      _strike(t, a, counter: true);
    }
    _checkVictory();
    return null;
  }

  void _strike(Unit a, Unit t, {bool counter = false}) {
    int dmg;
    if (counter) {
      dmg = max(1, attackPower(a) + (_adjacent(a.pos, t.pos) ? a.type.meleeBonus : 0) - 1 - defenseOf(t));
    } else {
      dmg = previewDamage(a, t);
      if (_flanked(a, t)) _log('log_flank', {'target': t.label});
      if (a.ambush) {
        _log('log_ambush', {'name': a.label});
        a.ambush = false;
      }
    }
    t.hp -= dmg;
    events.add(FxEvent(t.pos, '-$dmg', 0));
    _log(counter ? 'log_counter' : 'log_attack', {
      'name': a.label,
      'target': t.label,
      'dmg': dmg,
      'hp': max(0, t.hp),
    });
    if (t.hp <= 0) {
      units.remove(t);
      players[t.side]!.fallen.add(t.type);
      _log('log_defeat', {'target': t.label});
      _onDefeated(t);
    }
  }

  // ------------------------------------------------------ tactical cards

  List<Unit> validUnitTargets(CardDef c) {
    final mine = unitsOf(current).toList();
    final foes = units
        .where((u) => u.side != current && canSee(current, u) && !isGuarded(u))
        .toList();
    const cover = [Terrain.grove, Terrain.hills, Terrain.mountain, Terrain.dunes];
    return switch (c.effect) {
      CardEffect.heal => mine.where((u) => u.hp < u.maxHp).toList(),
      CardEffect.shield || CardEffect.rally => mine,
      CardEffect.fortify => mine.where((u) => u.bonusDef == 0).toList(),
      CardEffect.march => mine.where((u) => u.moved).toList(),
      CardEffect.ambush =>
        mine.where((u) => !u.ambush && cover.contains(map.terrainAt(u.pos))).toList(),
      CardEffect.drums =>
        foes.where((u) => u.weak == 0 && u.type.shape != AtkShape.none).toList(),
      CardEffect.sabotage => foes.where((u) => u.slow == 0).toList(),
      CardEffect.damage => foes,
      CardEffect.rush => mine.where((u) => u.moved || u.attacked).toList(),
      _ => <Unit>[],
    };
  }

  /// Free cell for a reinforcement: gates first, then city cells, then outside.
  Pos? spawnCell(City city, UnitType t) {
    bool free(Pos p) =>
        map.inBounds(p) &&
        unitAt(p) == null &&
        !map.terrainAt(p).impassable &&
        !(map.terrainAt(p) == Terrain.mountain && t.noMountain);
    for (final p in city.gates) {
      if (free(p)) return p;
    }
    for (final p in city.cells) {
      if (free(p)) return p;
    }
    for (final g in city.gates) {
      for (final n in g.neighbors) {
        if (free(n)) return n;
      }
    }
    return null;
  }

  /// Citadels of your cities that have room for reinforcements.
  Set<Pos> validCellTargets(CardDef c) {
    if (c.effect != CardEffect.reinforce) return {};
    final t = unitById[c.unitId]!;
    return {
      for (final e in cityOwner.entries)
        if (e.value == current && spawnCell(e.key, t) != null) e.key.citadel
    };
  }

  String? playTactical(CardDef c, {Unit? target, Pos? cell}) {
    final e = _battleErr(null);
    if (e != null) return e;
    if (!me.hand.contains(c)) return tr('err_hand');
    if (me.energy < c.cost) {
      return tr('err_energy', {'cost': c.cost, 'have': me.energy});
    }
    switch (c.target) {
      case TargetKind.friendlyUnit:
      case TargetKind.enemyUnit:
        if (target == null || !validUnitTargets(c).contains(target)) {
          return tr('err_target');
        }
      case TargetKind.ownCity:
        if (cell == null || !validCellTargets(c).contains(cell)) {
          return tr('err_target');
        }
      case TargetKind.anyCell:
        if (cell == null || !map.inBounds(cell)) return tr('err_target');
      case TargetKind.none:
        break;
    }
    me.energy -= c.cost;
    me.hand.remove(c);
    me.discard.add(c);
    _lastMoves.clear();
    _log('log_tactic', {'who': sideName(current), 'name': c.name});
    final t = target;
    switch (c.effect) {
      case CardEffect.heal:
        t!.hp = min(t.maxHp, t.hp + c.value);
        events.add(FxEvent(t.pos, '+${c.value}', 1));
        _log('log_heal', {'name': t.label, 'hp': t.hp});
      case CardEffect.shield:
        t!.tempDef += c.value;
        _log('log_shield', {'name': t.label});
      case CardEffect.fortify:
        t!.bonusDef += c.value;
        _log('log_fortify', {'name': t.label});
      case CardEffect.rally:
        for (final o in unitsOf(current)) {
          if (o.pos.dist(t!.pos) <= 1) o.tempAtk += c.value;
        }
        _log('log_rally', {'name': t!.label});
      case CardEffect.march:
        t!.moved = false;
        _log('log_march', {'name': t.label});
      case CardEffect.recon:
        _reveals.add(_Reveal(cell!, current));
        _invalidate();
        _log('log_recon', {'pos': cell});
      case CardEffect.energy:
        me.energy += c.value;
        _log('log_energy', {'who': sideName(current)});
      case CardEffect.drums:
        t!.weak = 1;
        _log('log_drums', {'name': t.label});
      case CardEffect.sabotage:
        t!.slow = 2;
        _log('log_sabotage', {'name': t.label});
      case CardEffect.sandstorm:
        sandstorm = 2;
        _log('log_sandstorm');
      case CardEffect.ambush:
        t!.ambush = true;
        _log('log_hide', {'name': t.label});
      case CardEffect.damage:
        final tx = t!;
        tx.hp -= c.value;
        events.add(FxEvent(tx.pos, '-${c.value}', 0));
        _log('log_arrows', {'name': tx.label, 'dmg': c.value, 'hp': max(0, tx.hp)});
        if (tx.hp <= 0) {
          units.remove(tx);
          players[tx.side]!.fallen.add(tx.type);
          _log('log_defeat', {'target': tx.label});
          _onDefeated(tx);
          _checkVictory();
        }
      case CardEffect.rush:
        final tr2 = t!;
        tr2.moved = false;
        tr2.attacked = false;
        _log('log_double', {'name': tr2.label});
      case CardEffect.reinforce:
        final type = unitById[c.unitId]!;
        final spot = spawnCell(map.cityAt(cell!)!, type)!;
        spawn(type, current, spot, ready: false);
        _log('log_reinforce', {'name': type.name, 'pos': spot});
    }
    return null;
  }

  // -------------------------------------------------------------- turns

  void startTurn(Side s) {
    current = s;
    final p = players[s]!;
    _reveals.removeWhere((r) => r.side == s);
    var e = baseEnergy;
    if (holdsOasis(s)) {
      e += 1;
      _log('log_oasis', {'who': sideName(s)});
    }
    if (ownedCities(s) >= 3) {
      e += 1;
      _log('log_cities', {'who': sideName(s)});
    }
    e += unitsOf(s).fold(0, (sum, u) => sum + u.type.energy);
    p.energy = e;
    _log('log_turn', {'who': sideName(s), 'n': round});
    final before = p.hand.length;
    if (_draw(p) && p.hand.length > before) {
      if (s == Side.player) {
        _log('log_draw_player', {'name': p.hand.last.name});
      } else {
        _log('log_draw_ai');
      }
    }
    for (final u in unitsOf(s)) {
      u.moved = false;
      u.attacked = false;
      u.tempDef = 0;
      u.tempAtk = 0;
    }
    for (final u in unitsOf(s)) {
      if (u.type.regen > 0 && u.hp < u.maxHp) {
        u.hp = min(u.maxHp, u.hp + u.type.regen);
        events.add(FxEvent(u.pos, '+${u.type.regen}', 1));
      }
    }
    for (final h in unitsOf(s).where((u) => u.type.healer).toList()) {
      for (final o in unitsOf(s)) {
        if (o != h && o.pos.dist(h.pos) <= 1 && o.hp < o.maxHp) {
          o.hp += 1;
          events.add(FxEvent(o.pos, '+1', 1));
        }
      }
    }
    _lastMoves.clear();
    if (s == Side.player && phase == Phase.battle) {
      _marchAll();
      _lastMoves.clear();
    }
    if (chapter != null && s == Side.player && phase == Phase.battle) {
      _fire('round:$round');
      if (chapter!.id == 'uhud') _uhudTick();
      _checkContact();
    }
  }

  void endTurn() {
    if (over || phase != Phase.battle) return;
    _lastMoves.clear();
    _captureCities(current);
    if (chapter?.id == 'badr_v2' && current == Side.player) {
      final holder = unitAt(chapter!.keyWell);
      final contested = unitsOf(Side.ai).any((e) => e.pos.dist(chapter!.keyWell) <= 1);
      if (holder != null && holder.side == Side.player && !contested) {
        _badrWellHoldTurns++;
        if (_badrWellHoldTurns == 2) _fire('b2_well_held');
      } else {
        _badrWellHoldTurns = 0;
      }
    }
    if (mode != GameMode.messenger) {
      _resolveCapture(current);
      if (over) return;
      if (unitAt(map.capitalOf(current))?.side != current.other) {
        players[current.other]!.objectiveProgress = 0;
      }
    }
    for (final u in unitsOf(current)) {
      u.weak = 0;
      u.slow = 0;
    }
    if (sandstorm > 0) sandstorm--;
    _invalidate();
    _checkVictory();
    if (over) return;
    if (current == Side.ai) {
      round++;
      if (round > roundLimit) {
        _timeUp();
        return;
      }
    }
    startTurn(current.other);
  }

  // ------------------------------------------------------------ helpers

  bool _draw(PlayerState p) {
    if (p.hand.length >= handLimit) return false;
    if (p.drawPile.isEmpty && p.discard.isNotEmpty) {
      p.drawPile.addAll(p.discard);
      p.discard.clear();
      p.drawPile.shuffle(rng);
    }
    if (p.drawPile.isEmpty) return false;
    p.hand.add(p.drawPile.removeLast());
    return true;
  }

  /// Neutral cities are defended at the start (not the ones in a capital zone).
  void _placeGarrisons() {
    const pool = ['spearmen', 'guard', 'archer', 'swordsman'];
    for (final city in map.cities) {
      if (city.capitalOf != null) continue;
      if (mode == GameMode.messenger && identical(city, map.messageCity)) continue;
      if (city.cells.any((p) => map.zoneOf(p) != null)) continue;
      final spots = [city.citadel, ...city.cells.where((p) => p != city.citadel)];
      final n = city.cells.length >= 9 ? 3 : 2;
      for (var i = 0; i < n && i < spots.length; i++) {
        spawn(unitById[pool[rng.nextInt(pool.length)]]!, Side.ai, spots[i]).garrison = true;
      }
    }
  }

  void _captureCities(Side s) {
    for (final city in cityOwner.keys.toList()) {
      final u = unitAt(city.citadel);
      if (u != null && !u.garrison && u.side == s && cityOwner[city] != s) {
        cityOwner[city] = s;
        _log('log_city', {'who': sideName(s), 'city': city.name});
      }
    }
  }

  /// Hold the enemy capital citadel, uncontested, for [captureTurns] turns.
  void _resolveCapture(Side s) {
    if (chapter?.noCaptureWin == true && s == Side.player) return;
    final p = players[s]!;
    final enemyCap = s == Side.player ? map.enemyCapital : map.playerCapital;
    final holder = unitAt(enemyCap.citadel);
    if (holder != null && holder.side == s) {
      if (objectiveContested(s)) {
        if (p.objectiveProgress > 0) _log('log_contested');
        p.objectiveProgress = 0;
      } else {
        p.objectiveProgress++;
        _log('log_objective', {
          'who': sideName(s),
          'city': enemyCap.name,
          'p': p.objectiveProgress,
          'n': captureTurns,
        });
        if (p.objectiveProgress >= captureTurns) {
          _win(s, tr('reason_objective', {'who': sideName(s), 'city': enemyCap.name, 'n': captureTurns}));
        }
      }
    } else {
      if (p.objectiveProgress > 0) _log('log_lost');
      p.objectiveProgress = 0;
    }
  }

  void _checkVictory() {
    if (over || phase != Phase.battle) return;
    final ch = chapter;
    if (ch?.id == 'badr_v2') {
      // Badr V2 is a multi-stage battle. Eliminating the commander alone is
      // deliberately insufficient: the player must secure and hold the well,
      // reach the battle phase, defeat the champions, clear both reserve waves,
      // and then have defeated Abu Jahl.
      final campaignComplete = objectiveDone('well') &&
          objectiveDone('night') && objectiveDone('champions') &&
          objectiveDone('reinforcements') && objectiveDone('leader');
      if (campaignComplete) {
        _win(Side.player, ch!.winReason);
        return;
      }
    } else if (ch != null && _defeated.contains(ch.leaderId)) {
      _win(Side.player, ch.winReason);
      return;
    }
    if (mode == GameMode.messenger &&
        !unitsOf(Side.player).any((u) => u.type.id == 'messenger')) {
      _win(Side.ai, tr('reason_messenger_dead'));
      return;
    }
    for (final s in Side.values) {
      if (!hasForces(s)) {
        // Badr V2 releases the historical force in staged reserve waves. Do
        // not award an early army-elimination victory before those waves and
        // the scenario objectives have had a chance to resolve.
        if (ch?.id == 'badr_v2' && s == Side.ai) continue;
        _win(s.other, tr('reason_army', {'loser': sideName(s)}));
        return;
      }
    }
  }

  void _timeUp() {
    if (mode == GameMode.story && chapter?.surviveToWin == true) {
      _win(Side.player, chapter!.winReason);
      return;
    }
    if (mode == GameMode.story) {
      _win(Side.ai, tr('reason_story_late', {'n': roundLimit}));
      return;
    }
    if (mode == GameMode.messenger) {
      _win(Side.ai, tr('reason_messenger_late', {'n': roundLimit}));
      return;
    }
    var diff = ownedCities(Side.player) - ownedCities(Side.ai);
    if (diff == 0) {
      diff = players[Side.player]!.objectiveProgress -
          players[Side.ai]!.objectiveProgress;
    }
    if (diff == 0) diff = totalHp(Side.player) - totalHp(Side.ai);
    if (diff == 0) {
      isDraw = true;
      endReason = tr('reason_time_draw', {'n': roundLimit});
      log.add(endReason);
    } else {
      final w = diff > 0 ? Side.player : Side.ai;
      _win(w, tr('reason_time', {'n': roundLimit, 'who': sideName(w)}));
    }
  }

  void _win(Side s, String reason) {
    winner = s;
    endReason = reason;
    log.add(reason);
    _fire(s == Side.player ? 'win' : 'lose');
  }

  // ------------------------------------------------------------- story

  /// Public progress values for the expanded Badr objective panel.
  int get badrWellHoldTurns => _badrWellHoldTurns;
  int get badrReserveRemaining => _badrReserveUnitIds.length;

  /// Done / not done for the chapter objectives (shown to the player).
  bool objectiveDone(String id) => switch (id) {
        'well' => chapter?.id == 'badr_v2'
            ? _badrWellHoldTurns >= 2
            : _fired.contains('well'),
        'leader' => chapter != null && _defeated.contains(chapter!.leaderId),
        'hq' => winner == Side.player,
        'night' => _fired.contains('b2_rain'),
        'hill' => _fired.contains('hill_ok'),
        'pursue' => _fired.contains('u_booty'),
        'champion' => _defeated.contains('sibaa'),
        'return' => _fired.contains('u_regroup'),
        'standard' => _defeated.contains('talhatalha'),
        'flank' => _fired.contains('u_flank_done') || _defeated.contains('khalid'),
        'refuge' => winner == Side.player,
        'champions' => _defeated.containsAll({'utba', 'shayba', 'walid'}),
        'reinforcements' => _fired.contains('b2_wave_two') && _badrReserveUnitIds.isEmpty,
        _ => false,
      };

  void _onDefeated(Unit t) {
    _defeated.add(t.type.id);
    _badrReserveUnitIds.remove(t.id);
    _fire('kill:${t.type.id}');
  }

  void _checkContact() {
    if (chapter == null || _fired.contains('contact')) return;
    if (units.any((e) => e.side == Side.ai && canSee(Side.player, e))) _fire('contact');
  }

  /// Queues the dialogue of every beat with this [trigger] (once each) and
  /// applies its effects.
  void _fire(String trigger) {
    final ch = chapter;
    if (ch == null) return;
    for (final b in ch.beats) {
      if (b.trigger != trigger || !_fired.add(b.id)) continue;
      _fired.add(trigger.startsWith('kill:') || trigger == 'well' || trigger == 'contact' ? trigger : b.id);
      storyQueue.add(b);
      if (b.healPlayer > 0) {
        for (final u in unitsOf(Side.player)) {
          u.hp = min(u.maxHp, u.hp + b.healPlayer);
          events.add(FxEvent(u.pos, '+${b.healPlayer}', 1));
        }
      }
      if (b.hurtEnemy > 0) {
        for (final u in unitsOf(Side.ai)) {
          if (u.hp > 1) {
            final loss = min(b.hurtEnemy, u.hp - 1);
            u.hp -= loss;
            events.add(FxEvent(u.pos, '-$loss', 0));
          }
        }
      }
      if (b.release) releaseHeld();
      if (b.rout) rout = true;
      final rear = ch.rearSpawn;
      for (final id in b.spawnRear) {
        final type = unitById[id];
        if (type == null || rear == null) continue;
        final spot = _freeNear(rear, type);
        if (spot != null) spawn(type, Side.ai, spot);
      }
      for (final id in b.spawnEnemy) {
        final type = unitById[id];
        if (type == null) continue;
        final spot = spawnCell(map.enemyCapital, type);
        if (spot != null) {
          final unit = spawn(type, Side.ai, spot);
          if (ch.id == 'badr_v2' &&
              (b.id == 'b2_wave_one' || b.id == 'b2_wave_two')) {
            _badrReserveUnitIds.add(unit.id);
          }
        }
      }
    }
  }

  // --------------------------------------------- scenario placement / hold

  /// Puts units from the roster of [s] on their scripted cells.
  void _placeStart(Side s, List<StoryStart> list) {
    final pl = players[s]!;
    for (final e in list) {
      final i = pl.roster.indexWhere((t) => t.id == e.id);
      if (i < 0 || unitAt(e.pos) != null) continue;
      final type = pl.roster.removeAt(i);
      final u = spawn(type, s, e.pos);
      u.hold = e.hold;
      u.guarded = e.guarded;
    }
  }

  /// A guarded enemy cannot be targeted until the protection is lifted.
  bool isGuarded(Unit t) => t.side == Side.ai && t.guarded && !_guardLifted;

  /// Waiting enemies start to act (and lose their protection).
  void releaseHeld() {
    for (final u in units) {
      if (u.side == Side.ai && (u.hold || u.guarded)) {
        u.hold = false;
        u.guarded = false;
      }
    }
  }

  /// Waiting enemies react when a player unit comes within [reach] cells.
  void wakeHeld({int reach = 2}) {
    final mine = unitsOf(Side.player).toList();
    for (final u in units) {
      if (u.side == Side.ai && u.hold && mine.any((p) => p.pos.dist(u.pos) <= reach)) {
        u.hold = false;
        u.guarded = false;
      }
    }
  }

  // ------------------------------------------------------- march orders

  /// Gives [u] a standing order to walk to [dest] by itself, turn after turn.
  /// A null [dest] cancels the order.
  String? setDestination(Unit u, Pos? dest) {
    final e = _battleErr(u);
    if (e != null) return e;
    if (u.side != Side.player) return tr('err_notmine');
    if (dest == null) {
      u.dest = null;
      return null;
    }
    if (!map.inBounds(dest) || enterCost(u, dest) == null) return tr('err_unreach');
    u.dest = dest;
    _log('log_march_order', {'name': u.label, 'pos': dest});
    if (!u.moved) {
      _marchStep(u);
      _lastMoves.clear();
    }
    return null;
  }

  /// Path distance (movement cost) from every cell to [goal] for [u].
  Map<Pos, int> _pathField(Pos goal, Unit u) {
    final best = <Pos, int>{goal: 0};
    final open = <Pos>[goal];
    while (open.isNotEmpty) {
      open.sort((a, b) => best[a]!.compareTo(best[b]!));
      final cur = open.removeAt(0);
      final cost = best[cur]!;
      for (final n in cur.neighbors) {
        if (!map.inBounds(n)) continue;
        final ec = enterCost(u, cur) ?? 1;
        if (enterCost(u, n) == null) continue;
        final nc = cost + ec;
        if (nc < (best[n] ?? 1 << 30)) {
          best[n] = nc;
          open.add(n);
        }
      }
    }
    return best;
  }

  bool _marchStep(Unit u) {
    final d = u.dest;
    if (d == null || u.moved) return false;
    if (u.pos == d) {
      u.dest = null;
      return false;
    }
    final threat = units.any((e) =>
        e.side != u.side && canSee(u.side, e) && e.pos.dist(u.pos) <= 5);
    if (threat) {
      u.dest = null;
      _log('log_march_stop', {'name': u.label});
      events.add(FxEvent(u.pos, '!', 2));
      return false;
    }
    if (u.pos.dist(d) <= 1 && unitAt(d) != null) {
      u.dest = null;
      return false;
    }
    final field = _pathField(d, u);
    var bestCost = field[u.pos] ?? (1 << 30);
    Pos? best;
    for (final e in reachable(u).entries) {
      final fd = field[e.key];
      if (fd != null && fd < bestCost) {
        bestCost = fd;
        best = e.key;
      }
    }
    if (best == null) return false;
    return move(u, best) == null;
  }

  void _marchAll() {
    for (final u in unitsOf(Side.player).toList()) {
      if (u.dest != null) _marchStep(u);
    }
  }

  /// Nearest free passable cell to [origin] (breadth-first, 4-neighbours).
  Pos? _freeNear(Pos origin, UnitType t) {
    final seen = <Pos>{origin};
    final queue = <Pos>[origin];
    for (var i = 0; i < queue.length && i < 400; i++) {
      final p = queue[i];
      if (map.inBounds(p) &&
          unitAt(p) == null &&
          !map.terrainAt(p).impassable &&
          !(map.terrainAt(p) == Terrain.mountain && t.noMountain)) {
        return p;
      }
      for (final n in p.neighbors) {
        if (map.inBounds(n) && seen.add(n)) queue.add(n);
      }
    }
    return null;
  }

  /// True while at least one player ranged unit stands on the watched hill.
  bool get hillHeld {
    final ch = chapter;
    if (ch == null) return false;
    return unitsOf(Side.player)
        .any((u) => u.type.ranged && ch.watchCells.contains(u.pos));
  }

  /// Uhud phase 2: the pursuit is over (the player reached the Quraysh camp,
  /// or time ran out). The enemy stops fleeing and Khalid's cavalry rides out
  /// toward the Muslim camp. A held hill weakens that charge.
  void _uhudPhase2({required bool late}) {
    if (_p2Round > 0) return;
    _p2Round = round;
    rout = false;
    final waiting = units.where((u) => u.side == Side.ai && (u.hold || u.guarded)).toList();
    _fire(late ? 'booty_late' : 'booty');
    if (hillHeld) {
      _fired.add('hill_ok');
      for (final u in waiting) {
        if (u.hp > 1) {
          final loss = min(2, u.hp - 1);
          u.hp -= loss;
          events.add(FxEvent(u.pos, '-$loss', 0));
        }
      }
      _fire('archers_held');
    } else {
      _fire('archers_left');
    }
    releaseHeld();
  }

  /// Player units gathered around their own camp.
  int get _campGuards {
    final c = map.playerCapital.citadel;
    return unitsOf(Side.player).where((u) => u.pos.dist(c) <= 3).length;
  }

  /// Uhud: called at the start of every round.
  void _uhudTick() {
    if (_p2Round == 0 && round >= 11) _uhudPhase2(late: true);
    if (_p2Round == 0) return;
    final k = round - _p2Round;
    if (k > 0) _fire('p2:$k');
    if (!_fired.contains('u_regroup') && (_campGuards >= 4 || k >= 9)) _fire('regroup');
    if (k >= 8 && !_defeated.contains('khalid')) _fire('flank_done');
  }

  void _log(String key, [Map<String, Object?> args = const {}]) {
    log.add(tr(key, args));
    _invalidate();
  }
}
