import 'package:flutter/material.dart';

import '../models/cards.dart';
import '../profile.dart';
import '../strings.dart';
import 'live_screen.dart';
import 'logo.dart';
import 'theme.dart';

String _t(String fr, String en) => currentLanguage == 'fr' ? fr : en;

/// Entrance of SARIYYA: pick a difficulty and a deck, then fight a best-of-3.
class LiveLobbyScreen extends StatefulWidget {
  const LiveLobbyScreen({super.key});

  @override
  State<LiveLobbyScreen> createState() => _LiveLobbyScreenState();
}

class _LiveLobbyScreenState extends State<LiveLobbyScreen> {
  int deckIndex = 0;
  int levelIndex = 1;

  static const levels = [1, 6, 11, 16];

  String _levelName(int i) => [_t('Facile', 'Easy'), _t('Normal', 'Normal'), _t('Difficile', 'Hard'), _t('Maître', 'Master')][i];

  @override
  Widget build(BuildContext context) {
    final deckList = Profile.playableDecks;
    if (deckIndex >= deckList.length) deckIndex = 0;
    final DeckDef deck = deckList[deckIndex];
    return Scaffold(
      backgroundColor: Pal.parchment,
      appBar: AppBar(title: const Text('SARIYYA')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: SariyyaWordmark(logoSize: 96, subtitle: _t('Le détachement', 'The detachment'))),
        const SizedBox(height: 12),
        Text(
          _t('Combat en temps réel : pose tes cartes, sélectionne tes troupes (un clic, ou un cadre autour de plusieurs), donne des consignes (tenir, escorter, poursuivre), choisis une formation, capture les villages et détruis la base ennemie. Match en 3 manches.',
              'Real-time combat: place your cards, select troops (tap, or draw a box), give orders (hold, escort, pursue), pick a formation, capture villages and destroy the enemy base. Best of 3.'),
          style: const TextStyle(color: Pal.ink, height: 1.4),
        ),
        const SizedBox(height: 14),
        Text(_t('Difficulté', 'Difficulty'), style: const TextStyle(fontWeight: FontWeight.w900, color: Pal.indigo)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          for (var i = 0; i < levels.length; i++)
            ChoiceChip(label: Text(_levelName(i)), selected: levelIndex == i, onSelected: (_) => setState(() => levelIndex = i)),
        ]),
        const SizedBox(height: 14),
        Text(_t('Deck', 'Deck'), style: const TextStyle(fontWeight: FontWeight.w900, color: Pal.indigo)),
        DropdownButton<int>(
          isExpanded: true,
          value: deckIndex,
          items: [for (var i = 0; i < deckList.length; i++) DropdownMenuItem(value: i, child: Text(deckList[i].name))],
          onChanged: (v) => setState(() => deckIndex = v ?? 0),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LiveScreen(deck: deck, level: levels[levelIndex], rounds: 3))),
          icon: const Icon(Icons.bolt_rounded),
          label: Text(_t('COMBATTRE (BO3)', 'FIGHT (BO3)')),
        ),
        const SizedBox(height: 8),
        Text(_t('Les étages « Direct » se trouvent dans LA TOUR, onglet Direct.', 'The "Direct" floors are in THE TOWER, Direct tab.'),
            style: const TextStyle(color: Pal.bronze, fontSize: 12)),
      ]),
    );
  }
}
