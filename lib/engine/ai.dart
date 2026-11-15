import 'dart:math';

import '../models/battlefield.dart';
import '../models/cards.dart';
import '../models/side.dart';
import '../models/terrain.dart';
import '../models/units.dart';
import 'game.dart';

/// Simple deterministic AI that plays for `game.current`.
/// It only reacts to enemy units it can actually see (fog of war).
/// Priorities each step: attack > tactic card > move.
/// Every step consumes a card or an action flag, so turns always end;
/// [maxActions] is an additional hard cap.
class Ai {
  static const int maxActions = 30;

  static void playTurn(Game g) {
    var n = 0;
    // Badr V2 has a deliberate pre-battle phase: the opposing force advances
    // and takes position during the consultation, reconnaissance and night
    // events, but does not begin attacks until the main clash (round 5).
    // The original Badr scenario keeps its original behavior.
    if (g.chapter?.id == 'badr_v2' && g.round <= 4) {
      while (n < maxActions && !g.over && _move(g)) {
        n++;
      }
      if (!g.over) g.endTurn();
      return;
    }
    while (n < maxActions && !g.over && step(g)) {
      n++;
    }
    if (!g.over) g.endTurn();
  }

  /// Performs ONE action; false when there is nothing useful left to do.
  static bool step(Game g) {
    if (g.over || g.phase != Phase.battle) return false;
    g.wakeHeld();
    return _attack(g) || _tactic(g) || _move(g);
  }

  static List<Unit> _visibleFoes(Game g) => g.units
      .where((u) => u.side != g.current && g.canSee(g.current, u))
      .toList();

  // ------------------------------------------------------------ attack

  static bool _attack(Game g) {
    Unit? bestA;
    Unit? bestT;
    var bestScore = -1e9;
    for (final a in g.unitsOf(g.current).toList()) {
      if (a.attacked || a.hold) continue;
      for (final t in g.attackTargets(a)) {
        final dmg = g.previewDamage(a, t);
        var score = dmg.toDouble() + (10 - t.hp);
        if (dmg >= t.hp) score += 100;
        if (t.type.id == 'messenger') score += 60;
        if (t.type.healer) score += 18;
        if (t.type.aura || t.type.defenseAura) score += 12;
        if (t.type.ranged) score += 5;
        score += t.type.rarity * 4; // named enemy heroes are high-value targets
        if (t.pos == g.map.capitalOf(g.current.other)) score += 10;
        score += g.canHit(t, t.pos, a.pos) ? -2 : 3;
        if (score > bestScore) {
          bestScore = score;
          bestA = a;
          bestT = t;
        }
      }
    }
    if (bestA == null || bestT == null) return false;
    return g.attack(bestA, bestT) == null;
  }

  // ------------------------------------------------------------ tactic

  static Unit? _best(Iterable<Unit> list, double Function(Unit) score) {
    Unit? best;
    var bs = -1e9;
    for (final u in list) {
      final s = score(u);
      if (best == null || s > bs) {
        best = u;
        bs = s;
      }
    }
    return best;
  }

  static Pos _goal(Game g, List<Unit> foes) {
    if (g.rout && g.current == Side.ai) return g.map.capitalOf(Side.ai);
    if (g.chapter != null && !g.objectiveDone('well') &&
        g.unitAt(g.chapter!.keyWell)?.side != g.current) {
      return g.chapter!.keyWell;
    }
    // In the expanded Badr scenario Quraysh contests the water position and
    // keeps a screen around its commander instead of sending every unit forward.
    if (g.chapter?.id == 'badr_v2' && g.current == Side.ai) {
      final commander = g.units.where((u) => u.side == Side.ai && u.type.id == 'abujahl');
      if (commander.isNotEmpty && foes.isEmpty) return commander.first.pos;
    }
    if (g.mode == GameMode.messenger && g.current == Side.ai) {
      for (final f in foes) {
        if (f.type.id == 'messenger') return f.pos;
      }
      return g.map.messageCity.citadel;
    }
    return g.map.capitalOf(g.current.other);
  }

  static bool _tactic(Game g) {
    final me = g.me;
    final foes = _visibleFoes(g);
    final mine = g.unitsOf(g.current).toList();
    bool threatened(Unit u, int r) => foes.any((f) => f.pos.dist(u.pos) <= r);

    for (final c in me.hand.toList()) {
      if (c.cost > me.energy) continue;
      final options = g.validUnitTargets(c);
      Unit? tu;
      Pos? cell;
      switch (c.effect) {
        case CardEffect.heal:
          tu = _best(options.where((u) => u.maxHp - u.hp >= 2),
              (u) => (u.maxHp - u.hp).toDouble());
        case CardEffect.shield:
          tu = _best(options.where((u) => u.tempDef == 0 && threatened(u, 4)),
              (u) => -u.hp.toDouble());
        case CardEffect.fortify:
          tu = _best(options.where((u) => threatened(u, 5)),
              (u) => u.hp.toDouble());
        case CardEffect.rally:
          tu = _best(
              options.where((u) => threatened(u, 3)),
              (u) => mine.where((o) => o.pos.dist(u.pos) <= 1).length.toDouble());
        case CardEffect.march:
          tu = _best(
              options.where((u) =>
                  !u.attacked &&
                  g.attackTargets(u).isEmpty &&
                  foes.any((f) => f.pos.dist(u.pos) <= u.type.move + 2)),
              (u) => -u.pos.dist(_goal(g, foes)).toDouble());
        case CardEffect.drums:
          tu = _best(options.where((u) => mine.any((m) => m.pos.dist(u.pos) <= 6)),
              (u) => u.type.attack.toDouble());
        case CardEffect.sabotage:
          tu = _best(options.where((u) => mine.any((m) => m.pos.dist(u.pos) <= 8)),
              (u) => -mine.map((m) => m.pos.dist(u.pos)).reduce(min).toDouble());
        case CardEffect.ambush:
          tu = _best(options.where((u) => threatened(u, 7)),
              (u) => u.hp.toDouble());
        case CardEffect.energy:
          final wanted = me.hand.any((x) =>
              x.effect == CardEffect.reinforce &&
              x.cost > me.energy &&
              x.cost <= me.energy + 1);
          if (!wanted) continue;
        case CardEffect.recon:
          if (me.hand.length <= 3) continue;
          cell = _goal(g, foes);
        case CardEffect.sandstorm:
          final theirs = foes.where((f) => f.type.ranged).length;
          final ours = mine.where((u) => u.type.ranged).length;
          if (theirs < 2 || ours > 1) continue;
        case CardEffect.damage:
          tu = _best(options, (u) => (u.hp <= c.value ? 100.0 : 0.0) + (10 - u.hp));
        case CardEffect.rush:
          tu = _best(options.where((u) => u.attacked && g.attackTargets(u).isNotEmpty),
              (u) => -u.hp.toDouble());
        case CardEffect.reinforce:
          final cities = g.validCellTargets(c);
          if (cities.isEmpty) continue;
          final goal = _goal(g, foes);
          cell = (cities.toList()..sort((a, b) => a.dist(goal).compareTo(b.dist(goal)))).first;
      }
      if ((c.target == TargetKind.friendlyUnit || c.target == TargetKind.enemyUnit) &&
          tu == null) {
        continue;
      }
      if ((c.target == TargetKind.ownCity || c.target == TargetKind.anyCell) &&
          cell == null) {
        continue;
      }
      return g.playTactical(c, target: tu, cell: cell) == null;
    }
    return false;
  }

  // -------------------------------------------------------------- move

  /// Path cost from every cell to [goal] (water blocks, mountains are slow).
  /// Cached per goal in the game: the terrain never changes.
  static Map<Pos, int> _distMap(Game g, Pos goal) {
    return g.distCache.putIfAbsent(goal, () {
      final best = <Pos, int>{goal: 0};
      final open = <Pos>[goal];
      while (open.isNotEmpty) {
        open.sort((a, b) => best[a]!.compareTo(best[b]!));
        final cur = open.removeAt(0);
        final cost = best[cur]!;
        for (final n in cur.neighbors) {
          if (!g.map.inBounds(n)) continue;
          final t = g.map.terrainAt(n);
          if (t.impassable) continue;
          final nc = cost + t.moveCost;
          final known = best[n];
          if (known == null || nc < known) {
            best[n] = nc;
            open.add(n);
          }
        }
      }
      return best;
    });
  }

  static bool _move(Game g) {
    final movers = g.unitsOf(g.current).where((u) => !u.moved && !u.garrison && !u.hold).toList();
    if (movers.isEmpty) return false;
    final foes = _visibleFoes(g);
    final dist = _distMap(g, _goal(g, foes));
    Unit? mover;
    Pos? dest;
    var gain = 0.0;
    for (final u in movers) {
      final here = _score(g, u, u.pos, dist, foes);
      for (final e in g.reachable(u).entries) {
        final s = _score(g, u, e.key, dist, foes);
        if (s - here > gain) {
          gain = s - here;
          mover = u;
          dest = e.key;
        }
      }
    }
    if (mover == null || dest == null) return false;
    return g.move(mover, dest) == null;
  }

  static double _score(Game g, Unit u, Pos p, Map<Pos, int> dist, List<Unit> foes) {
    var s = -2.0 * (dist[p] ?? 99);
    var nearest = 99;
    var canHit = false;
    for (final f in foes) {
      nearest = min(nearest, p.dist(f.pos));
      if (g.canHit(u, p, f.pos)) canHit = true;
      // Prefer squares that complete a pincer with an existing ally.
      if (p.dist(f.pos) == 1) {
        final opposite = Pos(f.pos.c + (f.pos.c - p.c), f.pos.r + (f.pos.r - p.r));
        if (g.unitsOf(g.current).any((ally) => ally != u && ally.pos == opposite)) s += 7;
      }
    }
    if (canHit && !u.attacked && u.type.shape != AtkShape.none) s += 30;
    if (foes.isNotEmpty && u.type.troopRole != 'guard') {
      s += g.rout && u.side == Side.ai ? nearest * 0.8 : -nearest * 0.5;
    }
    final t = g.map.terrainAt(p);
    final nearbyAllies = g.unitsOf(g.current).where((o) => o != u && o.pos.dist(p) <= 1).length;
    if (nearbyAllies == 1 || nearbyAllies == 2) s += 1.5;
    if (nearbyAllies >= 4) s -= 2;
    // Keep fragile ranged troops behind the line and wounded units out of danger.
    if (u.type.ranged && nearest <= 1) s -= 10;
    if (u.hp <= 2 && nearest <= 2) s -= 8;
    if ((u.type.healer || u.type.aura || u.type.defenseAura) && nearest <= 2) s -= 5;
    // Command and protection heroes are more useful when supporting allies.
    if (u.type.aura || u.type.defenseAura || u.type.healer) {
      final supported = g.unitsOf(g.current).where((o) => o != u && o.pos.dist(p) <= 1).length;
      s += min(4, supported * 1.5);
    }
    s += t.defense * 1.5;
    if (u.type.ranged) s += t.rangeBonus * 3;
    if (t == Terrain.dunes && !u.type.duneRider) s -= 1;
    if (u.type.minR >= 2 && nearest <= 1) s -= 8;
    if (g.mode != GameMode.messenger && !(g.rout && g.current == Side.ai) &&
        p == g.map.capitalOf(g.current.other)) {
      s += 20;
    }
    if (g.chapter != null && !g.objectiveDone('well') && p == g.chapter!.keyWell) s += 14;
    if (u.type.ranged && t.rangeBonus > 0) s += 2;
    if (u.type.noMountain && t == Terrain.mountain) s -= 100;
    // Badr V2: use infantry as a protective screen around Abu Jahl. The
    // commander avoids exposed forward tiles while nearby troops gain value
    // for maintaining a compact escort rather than blindly rushing the player.
    if (g.chapter?.id == 'badr_v2' && u.side == Side.ai) {
      final commander = g.units.where((o) =>
          o.side == Side.ai && o.type.id == 'abujahl').toList();
      if (commander.isNotEmpty) {
        final c = commander.first;
        final d = p.dist(c.pos);
        if (u.type.id == 'abujahl') {
          final nearestPlayer = foes.isEmpty
              ? 99
              : foes.map((f) => p.dist(f.pos)).reduce(min);
          final escort = g.unitsOf(Side.ai).where((o) =>
              o.id != u.id && o.pos.dist(p) <= 2).length;
          if (nearestPlayer <= 4) s -= (5 - nearestPlayer) * 2.0;
          s += min(5, escort * 1.5);
        } else if (!u.type.ranged && d <= 2) {
          s += d == 1 ? 5 : 3;
        }
      }
    }
    return s;
  }
}
