import 'package:flutter/material.dart';

import '../engine/game.dart';
import '../models/cards.dart';
import '../profile.dart';
import '../strings.dart';
import 'battle_screen.dart';
import 'icons.dart';
import 'theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  GameMode mode = GameMode.conquest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('setup_title'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(tr('setup_mode'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SegmentedButton<GameMode>(
                  segments: [
                    ButtonSegment(value: GameMode.conquest, label: Text(tr('mode_conquest'))),
                    ButtonSegment(value: GameMode.rush, label: Text(tr('mode_rush'))),
                    ButtonSegment(value: GameMode.messenger, label: Text(tr('mode_messenger'))),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => setState(() => mode = s.first),
                ),
                const SizedBox(height: 8),
                Text(tr(switch (mode) {
                  GameMode.conquest => 'mode_conquest_desc',
                  GameMode.rush => 'mode_rush_desc',
                  GameMode.messenger => 'mode_messenger_desc',
                  GameMode.story => 'mode_conquest_desc',
                })),
                const SizedBox(height: 12),
                Text(tr('setup_deck'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                for (final d in Profile.playableDecks) _DeckPanel(deck: d, mode: mode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckPanel extends StatelessWidget {
  const _DeckPanel({required this.deck, required this.mode});
  final DeckDef deck;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Pal.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Pal.bronze, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(deck.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Pal.green)),
            const SizedBox(height: 4),
            Text(deck.style, style: const TextStyle(color: Pal.bronze, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(deck.description),
            const SizedBox(height: 8),
            Text(tr('deck_army'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(deck.armySummary, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(tr('deck_key_cards'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in deck.featured)
                  Chip(
                    avatar: Icon(cardIcon(c), size: 16, color: Pal.bronze),
                    label: Text('${c.name} · ${c.cost}'),
                    backgroundColor: Pal.sand,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BattleScreen(deck: deck, mode: mode)),
                ),
                child: Text(tr('deck_start')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
