import 'package:flutter/material.dart';

import '../engine/game.dart';
import '../models/cards.dart';
import '../models/units.dart';
import '../profile.dart';
import '../story/tower.dart';
import '../strings.dart';
import 'battle_screen.dart';
import 'live_screen.dart';
import 'logo.dart';
import 'theme.dart';

/// End-game bonus mode: climb a tower of ever harder battles.
class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> {
  int deckIndex = 0;
  bool direct = false; // false = classic tower, true = Sariyya (real-time) towers
  String liveId = Tower.liveTowers.first.id;

  Future<void> _climbLive(DeckDef deck, int floor) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LiveScreen(deck: deck, towerId: liveId, towerFloor: floor)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _climb(DeckDef deck, int floor) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BattleScreen(deck: deck, mode: GameMode.rush, towerFloor: floor),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _floorRow(int floor, int best) {
    final boss = Tower.isBoss(floor);
    final done = floor <= best;
    final next = floor == best + 1;
    final card = Tower.rewardCard(floor);
    final bossName = boss ? (unitById[Tower.bossOf(floor)]?.name ?? '') : '';
    return Card(
      color: next ? Pal.sand : Pal.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: next ? Pal.gold : Pal.bronze.withAlpha(120), width: next ? 2 : 1),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: boss ? Pal.enemy : Pal.indigo,
          child: Text('$floor', style: const TextStyle(color: Pal.gold, fontWeight: FontWeight.w900)),
        ),
        title: Text(
          boss ? tr('tower_boss', {'name': bossName}) : tr('tower_floor', {'n': floor}),
          style: const TextStyle(fontWeight: FontWeight.w800, color: Pal.ink),
        ),
        subtitle: Text(
          tr('tower_reward', {'gold': Tower.gold(floor), 'xp': Tower.xp(floor)}) +
              (card == null ? '' : ' · ${unitById[card]?.name ?? ''}'),
          style: const TextStyle(color: Pal.bronze, fontSize: 12),
        ),
        trailing: done ? const Icon(Icons.check_circle, color: Pal.green) : (boss ? const Icon(Icons.shield, color: Pal.enemy) : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckList = Profile.playableDecks;
    if (deckIndex >= deckList.length) deckIndex = 0;
    final deck = deckList[deckIndex];
    final best = direct ? (Profile.towerLive[liveId] ?? 0) : Profile.towerBest;
    final start = Tower.startFloor(best);
    return Scaffold(
      appBar: AppBar(title: Text(tr('tower_title'))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(currentLanguage == 'fr' ? 'Classique' : 'Classic'), icon: const Icon(Icons.stairs_rounded)),
              ButtonSegment(value: true, label: const Text('Direct'), icon: const Icon(Icons.bolt_rounded)),
            ],
            selected: {direct},
            onSelectionChanged: (s) => setState(() => direct = s.first),
          ),
          const SizedBox(height: 10),
          if (direct) ...[
            for (final tw in Tower.liveTowers)
              Card(
                color: tw.id == liveId ? Pal.sand : Pal.parchment,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: tw.id == liveId ? Pal.gold : Pal.bronze.withAlpha(120), width: tw.id == liveId ? 2 : 1)),
                child: ListTile(
                  onTap: () => setState(() => liveId = tw.id),
                  leading: const SariyyaLogo(size: 34),
                  title: Text(currentLanguage == 'fr' ? tw.nameFr : tw.nameEn, style: const TextStyle(fontWeight: FontWeight.w900, color: Pal.ink)),
                  subtitle: Text(currentLanguage == 'fr' ? tw.descFr : tw.descEn, style: const TextStyle(fontSize: 12, color: Pal.bronze)),
                  trailing: Text('${Profile.towerLive[tw.id] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900, color: Pal.indigo, fontSize: 18)),
                ),
              ),
          ] else
            Text(tr('tower_desc'), style: const TextStyle(color: Pal.ink, height: 1.4)),
          const SizedBox(height: 10),
          Text(tr('tower_best', {'n': best}),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Pal.indigo)),
          const SizedBox(height: 10),
          DropdownButton<int>(
            isExpanded: true,
            value: deckIndex,
            items: [
              for (var i = 0; i < deckList.length; i++)
                DropdownMenuItem(value: i, child: Text(deckList[i].name)),
            ],
            onChanged: (v) => setState(() => deckIndex = v ?? 0),
          ),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            onPressed: () => direct ? _climbLive(deck, start) : _climb(deck, start),
            icon: const Icon(Icons.stairs_rounded),
            label: Text(tr('tower_start', {'n': start})),
          ),
          const SizedBox(height: 4),
          Text(tr('tower_checkpoint'), style: const TextStyle(color: Pal.bronze, fontSize: 12)),
          const SizedBox(height: 12),
          for (var f = start; f < start + 10 && f <= Tower.maxFloor; f++) _floorRow(f, best),
        ],
      ),
    );
  }
}
