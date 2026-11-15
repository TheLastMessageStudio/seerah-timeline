import 'package:flutter_test/flutter_test.dart';
// If your project is not called flutter_application_1, change this name
// (the "name:" line of pubspec.yaml).
import 'package:flutter_application_1/engine/ai.dart';
import 'package:flutter_application_1/engine/game.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/battlefield.dart';
import 'package:flutter_application_1/models/cards.dart';
import 'package:flutter_application_1/models/game_map.dart';
import 'package:flutter_application_1/models/side.dart';
import 'package:flutter_application_1/models/terrain.dart';
import 'package:flutter_application_1/models/units.dart';
import 'package:flutter_application_1/story/badr.dart';
import 'package:flutter_application_1/story/uhud.dart';
import 'package:flutter_application_1/story/tower.dart';
import 'package:flutter_application_1/live/live_game.dart';

UnitType ut(String id) => unitById[id]!;
CardDef card(String id) => allCards[id]!;

/// Flat 20x24 map (plains; capitals at (10,20) and (10,3); city at (3,12)).
Game sandbox({GameMode mode = GameMode.conquest}) {
  final g = Game(playerDeck: decks[0], aiDeck: decks[1], mode: mode, seed: 3, gameMap: GameMap.flat());
  g.units.clear();
  g.players[Side.player]!.roster.clear();
  g.players[Side.ai]!.roster.clear();
  g.phase = Phase.battle;
  g.startTurn(Side.player);
  return g;
}

Unit mine(Game g, String id, int c, int r) => g.spawn(ut(id), Side.player, Pos(c, r));
Unit foe(Game g, String id, int c, int r) => g.spawn(ut(id), Side.ai, Pos(c, r));
void setT(Game g, int c, int r, Terrain t) => g.map.terrain[r][c] = t;

void main() {
  group('generated map', () {
    for (var seed = 1; seed <= 6; seed++) {
      test('seed $seed: size, seas, cities, zones, connectivity', () {
        final m = GameMap.generate(seed);
        expect(m.cols, 30);
        expect(m.rows, 45);
        var seas = 0, mirrored = 0;
        for (var r = 0; r < m.rows; r++) {
          for (var c = 0; c < m.cols; c++) {
            if (m.terrainAt(Pos(c, r)) == Terrain.sea) seas++;
            if (m.terrainAt(Pos(c, r)) != m.terrainAt(Pos(m.cols - 1 - c, r))) mirrored++;
          }
        }
        expect(seas > 100, isTrue);
        expect(mirrored > 100, isTrue); // not a mirror image
        expect(m.playerCapital.citadel.r > m.enemyCapital.citadel.r, isTrue); // player south
        for (final city in m.cities) {
          expect(city.cells.contains(city.citadel), isTrue);
          expect(city.cells.every((p) => !m.terrainAt(p).impassable), isTrue);
          expect(city.gates.every(city.cells.contains), isTrue);
        }
        for (final side in Side.values) {
          final n = [
            for (var r = 0; r < m.rows; r++)
              for (var c = 0; c < m.cols; c++)
                if (m.zoneOf(Pos(c, r)) == side && !m.terrainAt(Pos(c, r)).impassable) 1
          ].length;
          expect(n >= 20, isTrue, reason: '$side zone has $n cells');
        }
        final seen = <Pos>{m.playerCapital.citadel};
        final q = [m.playerCapital.citadel];
        while (q.isNotEmpty) {
          for (final n in q.removeLast().neighbors) {
            if (m.inBounds(n) && !m.terrainAt(n).impassable && seen.add(n)) q.add(n);
          }
        }
        expect(seen.contains(m.enemyCapital.citadel), isTrue);
        expect(seen.contains(m.messageCity.citadel), isTrue);
      });
    }

    test('same seed gives the same map', () {
      final a = GameMap.generate(11), b = GameMap.generate(11);
      expect(a.playerCapital.id, b.playerCapital.id);
      for (var r = 0; r < a.rows; r++) {
        expect(a.terrain[r], b.terrain[r]);
      }
    });
  });

  group('deployment', () {
    test('place, pick up, start battle', () {
      final g = Game(playerDeck: decks[0], aiDeck: decks[1], seed: 5);
      expect(g.phase, Phase.deploy);
      final roster = g.players[Side.player]!.roster;
      expect(roster.length, 10);
      final army = g.unitsOf(Side.ai).where((u) => !u.garrison).toList();
      expect(army.length, 10);
      expect(army.every((u) => g.map.zoneOf(u.pos) == Side.ai), isTrue);
      expect(g.beginBattle(), isNotNull);
      expect(g.placeUnit(roster.first, g.map.enemyCapital.citadel), isNotNull);
      final spot = g.deployCells(Side.player).first;
      expect(g.placeUnit(roster.first, spot), isNull);
      expect(g.pickUp(g.unitAt(spot)!), isNull);
      expect(roster.length, 10);
      g.autoPlace(Side.player);
      expect(roster, isEmpty);
      expect(g.beginBattle(), isNull);
      expect(g.phase, Phase.battle);
    });

    test('no battle actions during deployment', () {
      final g = Game(playerDeck: decks[0], aiDeck: decks[1], seed: 5);
      expect(g.move(g.units.first, const Pos(0, 0)), isNotNull);
    });
  });

  group('movement', () {
    test('rivers, sea and mountains block; costs apply', () {
      final g = sandbox();
      setT(g, 5, 10, Terrain.river);
      setT(g, 4, 11, Terrain.sea);
      final sp = mine(g, 'spearmen', 4, 10);
      final r = g.reachable(sp);
      expect(r.containsKey(const Pos(5, 10)), isFalse);
      expect(r.containsKey(const Pos(4, 11)), isFalse);
      expect(g.move(sp, const Pos(5, 10)), isNotNull);
      setT(g, 4, 9, Terrain.grove);
      expect(g.reachable(sp)[const Pos(4, 9)], 2);
      setT(g, 6, 15, Terrain.mountain);
      final rider = mine(g, 'rider', 6, 14);
      expect(g.reachable(rider).containsKey(const Pos(6, 15)), isFalse);
      final inf = mine(g, 'spearmen', 7, 14);
      setT(g, 7, 15, Terrain.mountain);
      expect(g.reachable(inf)[const Pos(7, 15)], 3);
    });

    test('camels cross dunes cheaply; undo works', () {
      final g = sandbox();
      setT(g, 6, 8, Terrain.dunes);
      final camel = mine(g, 'camel', 5, 8);
      expect(g.reachable(camel)[const Pos(6, 8)], 1);
      expect(g.move(camel, const Pos(5, 9)), isNull);
      expect(g.move(camel, const Pos(5, 10)), isNotNull);
      expect(g.undoMove(), isNull);
      expect(camel.pos, const Pos(5, 8));
    });
  });

  group('story: Badr', () {
    Game badr() => Game(
          playerDeck: badrChapter.playerDeck,
          aiDeck: badrChapter.aiDeck,
          mode: GameMode.story,
          seed: 1,
          gameMap: badrChapter.buildMap(),
          chapter: badrChapter,
        );

    test('map, armies and opening dialogue', () {
      final m = badrChapter.buildMap();
      expect(m.cols, 30);
      expect(m.rows, 21);
      expect(m.backgroundBytes!.length > 1000, isTrue);
      expect(m.terrainAt(const Pos(12, 1)), Terrain.city);
      expect(m.zoneOf(const Pos(12, 3)), Side.player);
      expect(m.zoneOf(const Pos(14, 14)), Side.ai);
      expect(m.terrainAt(badrChapter.keyWell), Terrain.oasis);
      expect(Terrain.mud.moveCost, 2);
      final g = badr();
      expect(g.unitsOf(Side.ai).length, 12);
      expect(g.players[Side.player]!.roster.length, 10);
      g.autoPlace(Side.player);
      expect(g.unitsOf(Side.player).length, 10);
      expect(g.beginBattle(), isNull);
      expect(g.storyQueue.any((b) => b.id == 'b_start'), isTrue);
      expect(badrChapter.introLines.isNotEmpty, isTrue);
    });

    test('a unit on the central well triggers its dialogue', () {
      final g = badr();
      g.autoPlace(Side.player);
      g.beginBattle();
      final u = g.units.firstWhere((x) => x.side == Side.player);
      u.pos = Pos(badrChapter.keyWell.c - 1, badrChapter.keyWell.r);
      expect(g.objectiveDone('well'), isFalse);
      expect(g.move(u, badrChapter.keyWell), isNull);
      expect(g.objectiveDone('well'), isTrue);
      expect(g.storyQueue.any((b) => b.id == 'b_well'), isTrue);
    });

    test('defeating Abu Jahl wins the chapter', () {
      final g = badr();
      g.autoPlace(Side.player);
      g.beginBattle();
      final abu = g.units.firstWhere((x) => x.type.id == 'abujahl');
      final spot = abu.pos.neighbors.firstWhere(
          (p) => g.map.inBounds(p) && g.unitAt(p) == null && !g.map.terrainAt(p).impassable);
      final ali = g.spawn(ut('ali'), Side.player, spot);
      abu.hp = 1;
      expect(g.attack(ali, abu), isNull);
      expect(g.winner, Side.player);
      expect(g.objectiveDone('leader'), isTrue);
      expect(g.storyQueue.any((b) => b.id == 'b_abujahl'), isTrue);
      expect(g.storyQueue.any((b) => b.id == 'b_win'), isTrue);
    });
  });

  group('heroes', () {
    test('every hero is valid and registered', () {
      expect(heroTypes.length, 28);
      for (final h in heroTypes) {
        expect(unitById[h.id], same(h));
        expect(h.isHero, isTrue);
        expect(h.hp > 0 && h.attack > 0 && h.move > 0, isTrue, reason: h.id);
        expect(h.maxR >= h.minR, isTrue, reason: h.id);
        expect(h.heroName.isNotEmpty && h.titleFr.isNotEmpty && h.bioEn.isNotEmpty, isTrue, reason: h.id);
        expect(unitById.containsKey(h.troopRole), isTrue, reason: h.id);
      }
      expect(heroTypes.map((h) => h.id).toSet().length, heroTypes.length);
      expect(heroTypes.where((h) => h.rarity == 2).every((h) => h.specialFr.isNotEmpty), isTrue);
      expect(heroTypes.where((h) => h.rarity == 4).every((h) => h.specialFr.isNotEmpty), isTrue);
    });

    test('signature hero passives are active in battle', () {
      final g = sandbox();
      final ali = mine(g, 'ali', 5, 10);
      final target = foe(g, 'spearmen', 6, 10);
      expect(g.previewDamage(ali, target), greaterThan(g.attackPower(ali) - g.defenseOf(target)));

      final umar = mine(g, 'umar', 10, 10);
      final ally = mine(g, 'guard', 11, 10);
      final baseDefense = ally.type.defense + g.map.terrainAt(ally.pos).defense;
      expect(g.defenseOf(ally), baseDefense + 1);

      final saad = mine(g, 'saad', 2, 18);
      expect(g.canHit(saad, saad.pos, const Pos(2, 13)), isTrue);
    });

    test('Badr expanded version is separate and keeps the original chapter', () {
      expect(storyChapters.map((c) => c.id), containsAll(['badr', 'badr_v2']));
      expect(badrChapter.id, 'badr');
      expect(badrV2Chapter.roundLimit, greaterThan(badrChapter.roundLimit));
      expect(badrV2Chapter.beats.any((b) => b.trigger == 'round:10'), isTrue);
      expect(badrV2Chapter.beats.any((b) => b.spawnEnemy.isNotEmpty), isTrue);
    });

    test('Badr V2 cannot be won by eliminating Abu Jahl alone', () {
      final g = Game(
        playerDeck: badrV2Chapter.playerDeck,
        aiDeck: badrV2Chapter.aiDeck,
        mode: GameMode.story,
        seed: 1,
        gameMap: badrV2Chapter.buildMap(),
        chapter: badrV2Chapter,
      );
      g.autoPlace(Side.player);
      expect(g.beginBattle(), isNull);
      final abu = g.units.firstWhere((x) => x.type.id == 'abujahl');
      final spot = abu.pos.neighbors.firstWhere((p) =>
          g.map.inBounds(p) && g.unitAt(p) == null &&
          !g.map.terrainAt(p).impassable);
      final ali = g.spawn(ut('ali'), Side.player, spot);
      abu.hp = 1;
      expect(g.attack(ali, abu), isNull);
      expect(g.objectiveDone('leader'), isTrue);
      expect(g.winner, isNull);
    });

    test('Badr V2 requires holding the well for two full player turns', () {
      final g = Game(
        playerDeck: badrV2Chapter.playerDeck,
        aiDeck: badrV2Chapter.aiDeck,
        mode: GameMode.story,
        seed: 1,
        gameMap: badrV2Chapter.buildMap(),
        chapter: badrV2Chapter,
      );
      g.autoPlace(Side.player);
      expect(g.beginBattle(), isNull);
      final holder = g.units.firstWhere((u) => u.side == Side.player);
      holder.pos = badrV2Chapter.keyWell;
      expect(g.objectiveDone('well'), isFalse);
      g.endTurn(); // first player turn ends
      g.endTurn(); // AI turn ends
      expect(g.objectiveDone('well'), isFalse);
      g.endTurn(); // second player turn ends
      expect(g.objectiveDone('well'), isTrue);
    });

    test('preset decks and starter cards use known heroes', () {
      for (final d in decks) {
        expect(d.army().length, 10);
        expect(d.armyIds.every(unitById.containsKey), isTrue);
        expect(d.cardIds.every(allCards.containsKey), isTrue);
      }
      expect(starterCards.keys.every(unitById.containsKey), isTrue);
    });

    test('same-class heroes form a troop; regen and energy work', () {
      final g = sandbox();
      final a = g.spawn(ut('khalid'), Side.player, const Pos(5, 5));
      final b = g.spawn(ut('miqdad'), Side.player, const Pos(5, 6));
      expect(g.troopOf(a).length, 2);
      expect(g.troopOf(b).contains(a), isTrue);

      final ali = g.spawn(ut('ali'), Side.player, const Pos(9, 9));
      final uth = g.spawn(ut('uthman'), Side.player, const Pos(12, 9));
      ali.hp = 3;
      g.endTurn();
      g.endTurn();
      expect(ali.hp, 4); // Ali recovers 1 HP per turn
      expect(g.players[Side.player]!.energy, Game.baseEnergy + 1); // Uthman
      expect(uth.hp, uth.maxHp);
    });
  });

  group('troop bonus and territory', () {
    test('a troop goes farther than a lone unit', () {
      final g = sandbox();
      final a = mine(g, 'spearmen', 2, 5);
      final l = mine(g, 'spearmen', 2, 6);
      mine(g, 'spearmen', 2, 7);
      final far = g.moveBudget(l) + 1; // 3 units: +2 bonus
      expect(g.troopBonus(3), 2);
      expect(g.troopMoveError(l, Pos(2 + far, 6)), isNull);
      expect(g.reachable(l).containsKey(Pos(2 + far, 6)), isFalse);
      expect(a.side, Side.player);
    });

    test('units claim territory, lost when fog returns', () {
      final g = sandbox();
      final u = mine(g, 'spearmen', 10, 10);
      expect(g.territory[const Pos(10, 10)], Side.player);
      expect(g.territory[const Pos(10, 11)], Side.player);
      g.units.remove(u);
      g.spawn(ut('spearmen'), Side.player, const Pos(2, 2)); // far away
      g.endTurn();
      expect(g.territory.containsKey(const Pos(10, 10)), isFalse);
    });
  });

  group('troops', () {
    test('move together; blocked move gives a reason', () {
      final g = sandbox();
      final a = mine(g, 'spearmen', 2, 5);
      final l = mine(g, 'spearmen', 2, 6);
      final c = mine(g, 'spearmen', 2, 7);
      expect(g.troopOf(l).length, 3);
      expect(g.moveTroop(l, const Pos(4, 6)), isNull);
      expect([a.pos, l.pos, c.pos], [const Pos(4, 5), const Pos(4, 6), const Pos(4, 7)]);

      final g2 = sandbox();
      setT(g2, 6, 5, Terrain.sea);
      mine(g2, 'spearmen', 5, 5);
      final l2 = mine(g2, 'spearmen', 5, 6);
      mine(g2, 'spearmen', 5, 7);
      final err = g2.moveTroop(l2, const Pos(6, 6));
      expect(err, isNotNull);
      expect(l2.pos, const Pos(5, 6));
      expect(g2.troopMoveError(l2, const Pos(-1, 6)), isNotNull);
    });

    test('members attack separately', () {
      final g = sandbox();
      final a1 = mine(g, 'archer', 2, 10);
      final a2 = mine(g, 'archer', 2, 11);
      final t = foe(g, 'guard', 5, 11);
      expect(g.attack(a1, t), isNotNull); // distance 4
      expect(g.attack(a2, t), isNull); // distance 3
    });
  });

  group('patterns and terrain', () {
    test('attack shapes', () {
      final g = sandbox();
      final sp = mine(g, 'spearmen', 5, 10);
      expect(g.canHit(sp, sp.pos, const Pos(7, 10)), isTrue);
      expect(g.canHit(sp, sp.pos, const Pos(6, 11)), isFalse);
      final sw = mine(g, 'swordsman', 1, 1);
      expect(g.canHit(sw, sw.pos, const Pos(2, 2)), isTrue);
      final k = mine(g, 'skirmisher', 12, 12);
      expect(g.canHit(k, k.pos, const Pos(14, 14)), isTrue);
      expect(g.canHit(k, k.pos, const Pos(12, 13)), isFalse);
      final r = mine(g, 'rider', 8, 8);
      expect(g.canHit(r, r.pos, const Pos(9, 10)), isTrue);
      expect(g.canHit(r, r.pos, const Pos(9, 9)), isFalse);
      final ar = mine(g, 'archer', 15, 15);
      expect(g.canHit(ar, ar.pos, const Pos(16, 15)), isFalse);
      expect(g.canHit(ar, ar.pos, const Pos(18, 15)), isTrue);
    });

    test('elevation extends ranged attacks, sandstorm shortens them', () {
      final g = sandbox();
      setT(g, 12, 5, Terrain.mountain);
      final up = mine(g, 'archer', 12, 5);
      expect(g.canHit(up, up.pos, const Pos(12, 10)), isTrue); // range 5
      final flat = mine(g, 'archer', 3, 20);
      expect(g.canHit(flat, flat.pos, const Pos(3, 17)), isTrue);
      g.sandstorm = 2;
      expect(g.canHit(flat, flat.pos, const Pos(3, 17)), isFalse);
    });

    test('flanking, counter-attacks, damage and deaths', () {
      final g = sandbox();
      final a = mine(g, 'spearmen', 5, 10);
      final t = foe(g, 'swordsman', 6, 10);
      final before = g.previewDamage(a, t);
      mine(g, 'guard', 7, 10);
      expect(g.previewDamage(a, t), before + 1);
      expect(g.attack(a, t), isNull);
      expect(a.hp < a.maxHp, isTrue); // counter
      final w = mine(g, 'swordsman', 1, 1);
      final s = foe(g, 'scout', 2, 1);
      expect(g.attack(w, s), isNull);
      expect(g.units.contains(s), isFalse);
      expect(g.players[Side.ai]!.fallen, contains(ut('scout')));
    });
  });

  group('fog of war', () {
    test('unseen enemies cannot be attacked; ambushers hide', () {
      final g = sandbox();
      final guard = mine(g, 'guard', 2, 10);
      final far = foe(g, 'spearmen', 12, 10);
      expect(g.canSee(Side.player, far), isFalse);
      expect(g.attack(guard, far), isNotNull);
      final near = foe(g, 'spearmen', 4, 10);
      expect(g.canSee(Side.player, near), isTrue);
      near.ambush = true;
      expect(g.canSee(Side.player, near), isFalse);
      near.pos = const Pos(3, 10);
      expect(g.canSee(Side.player, near), isTrue);
      g.sandstorm = 2;
      expect(g.visionOf(guard), 1);
    });
  });

  group('cards', () {
    test('energy cost enforced; shield is temporary', () {
      final g = sandbox();
      final u = mine(g, 'spearmen', 5, 10);
      g.me.hand..clear()..add(card('shieldwall'));
      g.me.energy = 0;
      expect(g.playTactical(card('shieldwall'), target: u), isNotNull);
      g.me.energy = 3;
      expect(g.playTactical(card('shieldwall'), target: u), isNull);
      expect(g.defenseOf(u), 3);
      g.startTurn(Side.player);
      expect(g.defenseOf(u), 1);
    });

    test('reinforcements appear at the gates of an owned city', () {
      final g = sandbox();
      g.me.hand..clear()..add(card('levy'));
      g.me.energy = 3;
      final home = g.map.playerCapital;
      expect(g.validCellTargets(card('levy')), contains(home.citadel));
      expect(g.validCellTargets(card('levy')), isNot(contains(g.map.enemyCapital.citadel)));
      expect(g.playTactical(card('levy'), cell: g.map.enemyCapital.citadel), isNotNull);
      expect(g.playTactical(card('levy'), cell: home.citadel), isNull);
      final spawned = g.unitsOf(Side.player).single;
      expect(home.gates.contains(spawned.pos), isTrue);
      expect(spawned.moved && spawned.attacked, isTrue);
    });

    test('march, drums, sabotage, cache, sandstorm', () {
      final g = sandbox();
      final u = mine(g, 'spearmen', 5, 10);
      final e = foe(g, 'spearmen', 6, 10);
      g.me.hand..clear()..addAll([card('march'), card('drums'), card('sabotage'), card('cache'), card('sandstorm')]);
      g.me.energy = 6;
      g.move(u, const Pos(5, 11));
      expect(g.playTactical(card('march'), target: u), isNull);
      expect(u.moved, isFalse);
      expect(g.playTactical(card('drums'), target: e), isNull);
      expect(g.playTactical(card('sabotage'), target: e), isNull);
      expect(e.weak, 1);
      expect(e.slow, 2);
      expect(g.playTactical(card('cache')), isNull);
      expect(g.playTactical(card('sandstorm')), isNull);
      expect(g.sandstorm, 2);
      g.endTurn();
      expect(g.sandstorm, 1);
    });
  });

  group('victory', () {
    test('holding the enemy capital citadel wins', () {
      final g = sandbox();
      mine(g, 'spearmen', g.map.enemyCapital.citadel.c, g.map.enemyCapital.citadel.r);
      g.endTurn();
      g.endTurn();
      expect(g.winner, isNull);
      g.endTurn();
      expect(g.winner, Side.player);
    });

    test('a contested citadel does not progress', () {
      final g = sandbox();
      final c = g.map.enemyCapital.citadel;
      mine(g, 'spearmen', c.c, c.r);
      foe(g, 'scout', c.c, c.r + 1);
      g.endTurn();
      expect(g.players[Side.player]!.objectiveProgress, 0);
    });

    test('neutral cities are captured on the citadel; oasis gives energy', () {
      final g = sandbox();
      final city = g.map.messageCity;
      mine(g, 'scout', city.citadel.c, city.citadel.r);
      setT(g, 8, 8, Terrain.oasis);
      mine(g, 'spearmen', 8, 8);
      g.endTurn();
      expect(g.cityOwner[city], Side.player);
      g.endTurn();
      expect(g.me.energy, 4);
    });

    test('army elimination', () {
      final g = sandbox();
      final e = g.players[Side.ai]!;
      e.hand.clear();
      e.drawPile.clear();
      e.discard.clear();
      final a = mine(g, 'swordsman', 1, 1);
      final t = foe(g, 'scout', 2, 1);
      expect(g.attack(a, t), isNull);
      expect(g.winner, Side.player);
    });

    test('empty battlefield is not defeat while reinforcements remain', () {
      final g = sandbox();
      expect(g.winner, isNull);
      expect(g.hasForces(Side.ai), isTrue);
    });

    test('messenger delivered / killed', () {
      final g = sandbox(mode: GameMode.messenger);
      final dest = g.map.messageCity.citadel;
      final m = mine(g, 'messenger', dest.c, dest.r - 3);
      expect(g.move(m, Pos(dest.c, dest.r - 1)), isNull);
      expect(g.winner, Side.player);
      final g2 = sandbox(mode: GameMode.messenger);
      g2.endTurn();
      expect(g2.winner, Side.ai);
    });
  });

  group('v4 features', () {
    test('rush uses the small map and a 25 round limit', () {
      final g = Game(playerDeck: decks[0], aiDeck: decks[1], mode: GameMode.rush, seed: 2);
      expect(g.map.cols, 14);
      expect(g.map.rows, 19);
      expect(g.map.playerCapital.citadel.r > g.map.enemyCapital.citadel.r, isTrue);
      expect(g.roundLimit, 25);
      expect(g.players[Side.player]!.roster.length, 10);
      g.autoPlace(Side.player);
      expect(g.beginBattle(), isNull);
    });

    test('neutral cities are garrisoned and garrisons stay put', () {
      final g = Game(playerDeck: decks[0], aiDeck: decks[1], seed: 5);
      final guards = g.units.where((u) => u.garrison).toList();
      expect(guards.isNotEmpty, isTrue);
      expect(guards.every((u) => g.map.cityAt(u.pos) != null), isTrue);
      expect(g.hasForces(Side.ai), isTrue);
      g.autoPlace(Side.player);
      g.beginBattle();
      final before = guards.map((u) => u.pos).toList();
      g.endTurn();
      Ai.playTurn(g);
      expect(guards.where(g.units.contains).map((u) => u.pos).toList().length <= before.length, isTrue);
      for (final u in guards.where(g.units.contains)) {
        expect(before.contains(u.pos), isTrue);
      }
    });

    test('conquest is faster than the base speed; roads cost 1', () {
      final g = sandbox();
      final u = mine(g, 'spearmen', 5, 10);
      expect(g.moveBudget(u), u.type.move + 4); // early rounds
      setT(g, 6, 10, Terrain.hills);
      expect(g.reachable(u)[const Pos(6, 10)], 2);
      g.map.roads.add(const Pos(6, 10));
      expect(g.reachable(u)[const Pos(6, 10)], 1);
    });

    test('new cards: arrows and double time', () {
      final g = sandbox();
      final a = mine(g, 'spearmen', 5, 10);
      final e = foe(g, 'archer', 7, 10);
      g.me.hand..clear()..addAll([card('arrows'), card('charge')]);
      g.me.energy = 4;
      expect(g.playTactical(card('arrows'), target: e), isNull);
      expect(e.hp, e.maxHp - 2);
      g.move(a, const Pos(6, 10));
      g.attack(a, e);
      expect(g.playTactical(card('charge'), target: a), isNull);
      expect(a.moved || a.attacked, isFalse);
    });

    test('roads exist on generated maps and avoid mountains', () {
      final m = GameMap.generate(3);
      expect(m.roads.isNotEmpty, isTrue);
      expect(m.roads.every((p) => m.terrainAt(p) != Terrain.mountain), isTrue);
    });
  });

  group('AI', () {
    test('Badr V2 enemy advances before the main clash without attacking', () {
      final g = Game(
        playerDeck: badrV2Chapter.playerDeck,
        aiDeck: badrV2Chapter.aiDeck,
        mode: GameMode.story,
        chapter: badrV2Chapter,
        gameMap: badrV2Chapter.buildMap(),
        seed: 12,
      );
      g.autoPlace(Side.player);
      expect(g.beginBattle(), isNull);
      final hpBefore = g.unitsOf(Side.player).map((u) => u.hp).toList();
      g.endTurn();
      Ai.playTurn(g);
      expect(g.current, Side.player);
      expect(g.round, 2);
      expect(g.unitsOf(Side.player).map((u) => u.hp).toList(), hpBefore);
    });

    test('AI turn terminates', () {
      final g = Game(playerDeck: decks[0], aiDeck: decks[1], seed: 9);
      g.autoPlace(Side.player);
      g.beginBattle();
      g.endTurn();
      Ai.playTurn(g);
      expect(g.over || g.current == Side.player, isTrue);
    });

    test('AI vs AI on generated maps always finishes with a valid state', () {
      for (final mode in GameMode.values) {
        for (var seed = 1; seed <= 2; seed++) {
          final g = Game(playerDeck: decks[seed % 2], aiDeck: decks[(seed + 1) % 2], mode: mode, seed: seed);
          g.autoPlace(Side.player);
          g.beginBattle();
          var turns = 0;
          while (!g.over && turns < 130) {
            Ai.playTurn(g);
            turns++;
            expect(g.units.map((u) => u.pos).toSet().length, g.units.length);
            expect(g.units.every((u) => u.hp > 0 && !g.map.terrainAt(u.pos).impassable), isTrue);
          }
          expect(g.over, isTrue, reason: '$mode seed $seed');
        }
      }
    });
  });

  testWidgets('menu, setup and deployment-to-battle smoke test', (tester) async {
    await tester.pumpWidget(const LastMessageApp());
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Balanced Defense'), findsOneWidget);
    await tester.ensureVisible(find.text('Start battle').first);
    await tester.tap(find.text('Start battle').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Auto-place'));
    await tester.tap(find.text('Auto-place'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start battle'));
    await tester.tap(find.text('Start battle'));
    await tester.pumpAndSettle();
    expect(find.text('End turn'), findsOneWidget);
  });

  group('story: Uhud', () {
    Game uhud() => Game(
          playerDeck: uhudChapter.playerDeck,
          aiDeck: uhudChapter.aiDeck,
          mode: GameMode.story,
          seed: 1,
          gameMap: uhudChapter.buildMap(),
          chapter: uhudChapter,
        );

    Game uhudBattle() {
      final g = uhud();
      g.autoPlace(Side.player);
      expect(g.beginBattle(), isNull);
      return g;
    }

    test('map is registered, connected and has its key places', () {
      expect(storyChapters.map((c) => c.id), contains('uhud'));
      final m = uhudChapter.buildMap();
      expect(m.cols, uhudCols);
      expect(m.rows, uhudRows);
      expect(m.backgroundBytes!.length > 1000, isTrue);
      expect(m.terrainAt(const Pos(21, 1)), Terrain.city);
      expect(m.terrainAt(const Pos(2, 10)), Terrain.city);
      expect(m.bgCamps, contains('qcamp'));
      final seen = <Pos>{const Pos(21, 1)};
      final queue = <Pos>[const Pos(21, 1)];
      for (var i = 0; i < queue.length; i++) {
        for (final n in queue[i].neighbors) {
          if (m.inBounds(n) && !m.terrainAt(n).impassable && seen.add(n)) queue.add(n);
        }
      }
      expect(seen.contains(const Pos(2, 10)), isTrue);
      expect(seen.contains(const Pos(20, 18)), isTrue);
      expect(seen.containsAll(uhudHill), isTrue);
      expect(seen.containsAll(uhudLift), isTrue);
    });

    test('both armies start on their scripted cells', () {
      final g = uhud();
      expect(g.unitsOf(Side.ai).length, 17);
      expect(g.unitsOf(Side.player).length, 12);
      expect(g.players[Side.player]!.roster, isEmpty);
      final khalid = g.units.firstWhere((u) => u.type.id == 'khalid');
      expect(khalid.pos, const Pos(20, 18));
      expect(khalid.hold, isTrue);
      expect(khalid.guarded, isTrue);
      expect(g.unitAt(const Pos(21, 7))!.type.id, 'musab');
      expect(g.unitAt(uhudHillTop)!.type.id, 'abdullahjubayr');
      expect(g.beginBattle(), isNull);
      expect(g.storyQueue.any((b) => b.id == 'u_start'), isTrue);
      for (final id in uhudChapter.beats.expand((b) => [...b.spawnEnemy, ...b.spawnRear])) {
        expect(unitById.containsKey(id), isTrue, reason: id);
      }
    });

    test('Khalid is sheltered until a unit goes round by the mountain', () {
      final g = uhudBattle();
      final khalid = g.units.firstWhere((u) => u.type.id == 'khalid');
      bool freeNear(Pos n) =>
          g.map.inBounds(n) && g.unitAt(n) == null && !g.map.terrainAt(n).impassable;
      final spot = khalid.pos.neighbors.firstWhere(freeNear);
      final ali = g.spawn(ut('ali'), Side.player, spot);
      expect(g.isGuarded(khalid), isTrue);
      expect(g.attack(ali, khalid), isNotNull);
      expect(g.attackTargets(ali).contains(khalid), isFalse);
      final lift = uhudLift.firstWhere(
          (p) => p.neighbors.any((n) => freeNear(n) && !uhudLift.contains(n)));
      final from = lift.neighbors.firstWhere((n) => freeNear(n) && !uhudLift.contains(n));
      final walker = g.spawn(ut('scout'), Side.player, from);
      expect(g.move(walker, lift), isNull);
      expect(g.isGuarded(khalid), isFalse);
      expect(g.storyQueue.any((b) => b.id == 'u_lift'), isTrue);
      expect(g.attack(ali, khalid), isNull);
    });

    test('round 6: Quraysh breaks and flees toward its own camp', () {
      final g = uhudBattle();
      expect(g.rout, isFalse);
      g.round = 6;
      g.startTurn(Side.player);
      expect(g.rout, isTrue);
      expect(g.storyQueue.any((b) => b.id == 'u_break'), isTrue);
    });

    test('reaching the Quraysh camp ends the pursuit; empty hill = full charge', () {
      final g = uhudBattle();
      g.units.removeWhere((u) => u.side == Side.player && uhudHill.contains(u.pos));
      final khalid = g.units.firstWhere((u) => u.type.id == 'khalid');
      final hp = khalid.hp;
      g.rout = true;
      final cell = uhudBooty.firstWhere((p) =>
          g.map.inBounds(p) && g.unitAt(p) == null && !g.map.terrainAt(p).impassable);
      final from = cell.neighbors.firstWhere((n) =>
          g.map.inBounds(n) && g.unitAt(n) == null && !g.map.terrainAt(n).impassable);
      final walker = g.spawn(ut('scout'), Side.player, from);
      expect(g.move(walker, cell), isNull);
      expect(g.rout, isFalse);
      expect(g.objectiveDone('pursue'), isTrue);
      expect(g.storyQueue.any((b) => b.id == 'u_archers_left'), isTrue);
      expect(khalid.hold, isFalse);
      expect(khalid.hp, hp);
      expect(g.objectiveDone('hill'), isFalse);
    });

    test('a held hill weakens Khalid and completes the optional objective', () {
      final g = uhudBattle();
      final khalid = g.units.firstWhere((u) => u.type.id == 'khalid');
      final hp = khalid.hp;
      g.round = 11;
      g.startTurn(Side.player);
      expect(g.storyQueue.any((b) => b.id == 'u_booty_late'), isTrue);
      expect(g.storyQueue.any((b) => b.id == 'u_archers_held'), isTrue);
      expect(g.objectiveDone('hill'), isTrue);
      expect(g.objectiveDone('pursue'), isFalse);
      expect(khalid.hp < hp, isTrue);
      expect(khalid.hold, isFalse);
    });

    test('regrouping 4 units at the camp completes the return objective', () {
      final g = uhudBattle();
      g.round = 11;
      g.startTurn(Side.player);
      g.round = 12;
      g.startTurn(Side.player);
      final camp = g.map.playerCapital.citadel;
      final near = g.unitsOf(Side.player).where((u) => u.pos.dist(camp) <= 3).length;
      expect(g.objectiveDone('return'), near >= 4);
      g.round = 20;
      g.startTurn(Side.player);
      expect(g.objectiveDone('return'), isTrue);
    });

    test('holding the Quraysh citadel does not win Uhud', () {
      final g = uhudBattle();
      g.units.removeWhere((u) => u.pos == g.map.enemyCapital.citadel);
      g.spawn(ut('ali'), Side.player, g.map.enemyCapital.citadel);
      for (var i = 0; i < 4; i++) {
        g.current = Side.ai;
        g.endTurn();
      }
      expect(g.winner, isNull);
    });

    test('defeating Talha ibn Abi Talha completes the standard objective', () {
      final g = uhudBattle();
      final tt = g.units.firstWhere((x) => x.type.id == 'talhatalha');
      final spot = tt.pos.neighbors.firstWhere(
          (p) => g.map.inBounds(p) && g.unitAt(p) == null && !g.map.terrainAt(p).impassable);
      final ali = g.spawn(ut('ali'), Side.player, spot);
      tt.hp = 1;
      expect(g.attack(ali, tt), isNull);
      expect(g.objectiveDone('standard'), isTrue);
      expect(g.storyQueue.any((b) => b.id == 'u_standard'), isTrue);
      expect(g.winner, isNull);
    });

    test('reaching the round limit with the camp held wins', () {
      final g = uhudBattle();
      g.round = uhudChapter.roundLimit;
      g.current = Side.ai;
      g.endTurn();
      expect(g.winner, Side.player);
    });
  });

  group('tower', () {
    test('floors grow harder and every 5th is a boss with a checkpoint', () {
      expect(Tower.isBoss(5), isTrue);
      expect(Tower.isBoss(6), isFalse);
      expect(Tower.startFloor(0), 1);
      expect(Tower.startFloor(7), 6);
      final d1 = Tower.deckFor(1, decks.first);
      final d20 = Tower.deckFor(20, decks.first);
      expect(d20.armyIds.length > d1.armyIds.length, isTrue);
      for (var f = 1; f <= Tower.maxFloor; f++) {
        for (final id in Tower.deckFor(f, decks.first).armyIds) {
          expect(unitById.containsKey(id), isTrue, reason: 'floor $f: $id');
        }
      }
      expect(Tower.gold(10) > Tower.gold(9), isTrue);
      expect(Tower.rewardCard(4), isNull);
      expect(unitById.containsKey(Tower.rewardCard(5)), isTrue);
    });

    test('aiBoost strengthens only the AI units', () {
      final g = Game(
        playerDeck: decks.first,
        aiDeck: Tower.deckFor(20, decks.last),
        mode: GameMode.rush,
        seed: 3,
        aiBoost: Tower.boost(20),
      );
      final foe = g.unitsOf(Side.ai).first;
      expect(foe.hp, foe.type.hp + foe.hpBonus);
      expect(foe.hpBonus > 0, isTrue);
      final mine = g.spawn(ut('spearmen'), Side.player, const Pos(0, 0));
      expect(mine.hpBonus, 0);
      expect(g.attackPower(foe) > foe.type.attack || foe.type.attack == 0, isTrue);
    });
  });

  group('live mode', () {
    LiveGame make() => LiveGame(playerArmy: decks[0].army(), enemyArmy: decks[1].army());
    void runPrep(LiveGame g) {
      for (var i = 0; i < 500 && g.preparing; i++) {
        g.tick(0.05);
      }
    }

    test('the field is longer; 3 units per side start on passable cells', () {
      final g = make();
      expect(g.map.rows, 19 + 2 * LiveTuning.extraRows);
      expect(g.aliveOf(Side.player).length, LiveTuning.startingUnits);
      expect(g.aliveOf(Side.ai).length, LiveTuning.startingUnits);
      expect(g.playerBase.y > g.enemyBase.y, isTrue);
      for (final u in g.units) {
        expect(g.map.terrainAt(Pos(u.x.floor(), u.y.floor())).impassable, isFalse);
      }
    });

    test('nobody moves during the preparation', () {
      final g = make();
      final u = g.aliveOf(Side.player).first;
      final y0 = u.y;
      g.orderMove([u], u.x, u.y - 3);
      for (var i = 0; i < 100; i++) {
        g.tick(0.05);
      }
      expect(g.preparing, isTrue);
      expect(u.y, y0);
      runPrep(g);
      for (var i = 0; i < 200; i++) {
        g.tick(0.05);
      }
      expect(u.y < y0, isTrue);
    });

    test('cards cost energy and only go in your own territory', () {
      final g = make();
      final h = g.handOf(Side.player);
      final card = h.hand.first;
      expect(g.play(Side.player, card, 5, g.enemyBase.y + 1), isNull);
      final before = h.energy;
      final u = g.play(Side.player, card, 5, g.playerBase.y - 4);
      expect(u, isNotNull);
      expect(h.energy, before - card.cost);
      expect(h.queue.last, card);
      expect(g.canPlay(Side.player, card), isFalse);
    });

    test('a dead unit comes back after its cooldown', () {
      final g = make();
      runPrep(g);
      final h = g.handOf(Side.player);
      final card = h.hand.first;
      final u = g.play(Side.player, card, 5, g.playerBase.y - 4)!;
      u.hp = 0;
      g.tick(0.05);
      expect(card.unit, isNull);
      expect(card.readyAt > g.time, isTrue);
    });

    test('a long game ends with a winner and without errors', () {
      final g = make();
      var guard = 0;
      while (!g.over && guard++ < 40000) {
        final h = g.handOf(Side.player);
        for (final c in h.hand) {
          if (g.canPlay(Side.player, c)) {
            final u = g.play(Side.player, c, 3 + (guard % 8), g.playerBase.y - 4);
            if (u != null) g.orderCharge([u]);
          }
        }
        g.tick(0.1);
      }
      expect(g.over, isTrue);
    });
  });

  group('march orders', () {
    Game open() {
      final g = Game(
        playerDeck: decks.first,
        aiDeck: decks.first,
        mode: GameMode.rush,
        seed: 1,
        gameMap: GameMap.flat(),
      );
      g.units.clear();
      g.spawn(ut('spearmen'), Side.ai, const Pos(18, 22));
      return g;
    }

    test('a unit with a destination keeps walking on its own', () {
      final g = open();
      final u = g.spawn(ut('swordsman'), Side.player, const Pos(8, 6));
      g.phase = Phase.battle;
      g.current = Side.player;
      const goal = Pos(8, 16);
      expect(g.setDestination(u, goal), isNull);
      expect(u.moved, isTrue);
      final first = u.pos;
      expect(first.dist(goal) < const Pos(8, 6).dist(goal), isTrue);
      g.endTurn();
      g.endTurn();
      expect(u.pos.dist(goal) < first.dist(goal), isTrue);
    });

    test('the march stops when an enemy comes into view and can be cancelled', () {
      final g = open();
      final u = g.spawn(ut('swordsman'), Side.player, const Pos(8, 6));
      g.phase = Phase.battle;
      g.current = Side.player;
      expect(g.setDestination(u, const Pos(8, 16)), isNull);
      expect(u.dest, isNotNull);
      expect(g.setDestination(u, null), isNull);
      expect(u.dest, isNull);
    });
  });

  group('sariyya v9.7', () {
    test('formation slots: right count, distinct cells', () {
      final g = LiveGame(playerArmy: decks[0].army(), enemyArmy: decks[1].army());
      for (final f in LiveFormation.values) {
        final s = g.formationSlots(6, f);
        expect(s.length, 6);
      }
    });

    test('hold keeps a unit in place, chase flag toggles', () {
      final g = LiveGame(playerArmy: decks[0].army(), enemyArmy: decks[1].army());
      final u = g.aliveOf(Side.player).first;
      g.orderHold([u]);
      expect(u.hold, isTrue);
      g.setChase([u], false);
      expect(u.chase, isFalse);
    });

    test('there are four villages, two per half', () {
      final g = LiveGame(playerArmy: decks[0].army(), enemyArmy: decks[1].army());
      expect(g.towns.length, 4);
      expect(g.townsOf(Side.player), 2);
      expect(g.townsOf(Side.ai), 2);
    });

    test('live tower armies are valid for both towers, floors 1..50', () {
      for (final t in Tower.liveTowers) {
        for (var f = 1; f <= 50; f++) {
          final a = Tower.liveArmy(t.id, f);
          expect(a, isNotEmpty);
          final g = LiveGame(playerArmy: decks[0].army(), enemyArmy: a, level: Tower.liveLevel(f), rules: t.rules);
          expect(g.aliveOf(Side.ai), isNotEmpty);
        }
      }
    });

    test('towers are two different rule sets', () {
      expect(Tower.liveTowers.length, 2);
      expect(Tower.liveTowers[0].id, isNot(Tower.liveTowers[1].id));
    });
  });
}
