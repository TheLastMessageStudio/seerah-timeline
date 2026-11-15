import 'package:flutter/material.dart';

import '../engine/game.dart';
import '../models/terrain.dart';
import '../strings.dart';
import 'theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  Widget _section(String head, String body) => Card(
        color: Pal.parchment,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(head,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Pal.green)),
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final args = {'n': Game.maxRounds, 'k': Game.captureTurns, 't': Game.maxTroop};
    return Scaffold(
      appBar: AppBar(title: Text(tr('rules_title'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final k in ['setup', 'turns', 'cards', 'move', 'troops', 'attack', 'fog'])
                  _section(tr('rules_${k}_h'), tr('rules_${k}_b', args)),
                Card(
                  color: Pal.parchment,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('rules_terrain_h'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Pal.green)),
                        const SizedBox(height: 8),
                        for (final t in Terrain.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(right: 10, top: 2),
                                  decoration: BoxDecoration(
                                    color: terrainColor(t),
                                    border: Border.all(color: Pal.bronze),
                                  ),
                                ),
                                Expanded(
                                  child: Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: '${t.label}: ',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: t.description),
                                  ])),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _section(tr('rules_win_h'), tr('rules_win_b', args)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
