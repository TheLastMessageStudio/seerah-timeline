import 'package:flutter/material.dart';

import '../models/cards.dart';
import '../models/units.dart';
import '../profile.dart';
import '../strings.dart';
import 'hero_card.dart';
import 'icons.dart';
import 'theme.dart';

/// Build or edit a custom deck: pick heroes you own and tactic cards.
class DeckEditorScreen extends StatefulWidget {
  const DeckEditorScreen({super.key, this.deck});
  final CustomDeck? deck;

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  late final TextEditingController nameCtl;
  final Map<String, int> army = {};
  final Map<String, int> tactics = {};
  String? error;

  @override
  void initState() {
    super.initState();
    final d = widget.deck;
    nameCtl = TextEditingController(text: d?.name ?? tr('deck_default_name', {'n': Profile.customDecks.length + 1}));
    for (final i in d?.army ?? <String>[]) {
      if (Profile.copiesOf(i) > 0) army[i] = (army[i] ?? 0) + 1;
    }
    for (final i in d?.cards ?? defaultTactics) {
      if (allCards.containsKey(i)) tactics[i] = (tactics[i] ?? 0) + 1;
    }
    // never more copies than you own
    army.updateAll((k, v) => v > Profile.copiesOf(k) ? Profile.copiesOf(k) : v);
  }

  @override
  void dispose() {
    nameCtl.dispose();
    super.dispose();
  }

  int get armyCount => army.values.fold(0, (a, b) => a + b);
  int get tacticCount => tactics.values.fold(0, (a, b) => a + b);

  void _changeArmy(String id, int delta) {
    final cur = army[id] ?? 0;
    final next = cur + delta;
    if (next < 0 || next > Profile.copiesOf(id)) return;
    if (delta > 0 && armyCount >= maxArmy) return;
    setState(() {
      error = null;
      if (next == 0) {
        army.remove(id);
      } else {
        army[id] = next;
      }
    });
  }

  void _changeTactic(String id, int delta) {
    final cur = tactics[id] ?? 0;
    final next = cur + delta;
    if (next < 0 || next > maxTacticCopies) return;
    if (delta > 0 && tacticCount >= maxTactics) return;
    setState(() {
      error = null;
      if (next == 0) {
        tactics.remove(id);
      } else {
        tactics[id] = next;
      }
    });
  }

  void _autoArmy() {
    final owned = heroTypes.where((h) => Profile.copiesOf(h.id) > 0).toList()
      ..sort((a, b) => b.rarity.compareTo(a.rarity));
    army.clear();
    var n = 0;
    for (final h in owned) {
      var c = Profile.copiesOf(h.id);
      while (c > 0 && n < maxArmy) {
        army[h.id] = (army[h.id] ?? 0) + 1;
        c--;
        n++;
      }
    }
    setState(() => error = null);
  }

  void _save() {
    final name = nameCtl.text.trim();
    if (name.isEmpty) {
      setState(() => error = tr('deck_err_name'));
      return;
    }
    if (armyCount < minArmy) {
      setState(() => error = tr('deck_err_army', {'n': minArmy}));
      return;
    }
    if (tacticCount < minTactics) {
      setState(() => error = tr('deck_err_tactics', {'n': minTactics}));
      return;
    }
    final armyList = [
      for (final e in army.entries)
        for (var i = 0; i < e.value; i++) e.key
    ];
    final cardList2 = [
      for (final e in tactics.entries)
        for (var i = 0; i < e.value; i++) e.key
    ];
    final d = widget.deck;
    if (d == null) {
      Profile.addDeck(CustomDeck(name, armyList, cardList2));
    } else {
      d.name = name;
      d.army = armyList;
      d.cards = cardList2;
      Profile.save();
    }
    Navigator.of(context).pop();
  }

  Widget _counter(int value, VoidCallback minus, VoidCallback plus) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 0 ? minus : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 22,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: plus,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      );

  Widget _heroRow(UnitType t) {
    final v = army[t.id] ?? 0;
    return Card(
      color: v > 0 ? const Color(0xFFE6F0DC) : Pal.parchment,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => showHeroDialog(context, t, owned: Profile.copiesOf(t.id)),
              child: heroPortrait(t, 40),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => showHeroDialog(context, t, owned: Profile.copiesOf(t.id)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${tr('stat_atk')} ${t.attack} · ${tr('stat_def')} ${t.defense} · ${tr('stat_hp')} ${t.hp} · ${tr('stat_move')} ${t.move}  (×${Profile.copiesOf(t.id)})',
                      style: TextStyle(fontSize: 11, color: rarityColor(t.rarity), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            _counter(v, () => _changeArmy(t.id, -1), () => _changeArmy(t.id, 1)),
          ],
        ),
      ),
    );
  }

  Widget _tacticRow(CardDef c) {
    final v = tactics[c.id] ?? 0;
    return Card(
      color: v > 0 ? const Color(0xFFE6F0DC) : Pal.parchment,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Pal.green,
              child: Text('${c.cost}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Icon(cardIcon(c), size: 18, color: Pal.bronze),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            _counter(v, () => _changeTactic(c.id, -1), () => _changeTactic(c.id, 1)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owned = heroTypes.where((h) => Profile.copiesOf(h.id) > 0).toList()
      ..sort((a, b) => b.rarity.compareTo(a.rarity));
    return Scaffold(
      appBar: AppBar(title: Text(widget.deck == null ? tr('deck_new') : tr('deck_edit'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(error!, style: const TextStyle(color: Pal.enemy, fontWeight: FontWeight.bold)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(tr('deck_save')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: nameCtl,
                  maxLength: 24,
                  decoration: InputDecoration(labelText: tr('deck_name')),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(tr('deck_army_count', {'n': armyCount, 'max': maxArmy, 'min': minArmy}),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    TextButton(onPressed: _autoArmy, child: Text(tr('deck_auto'))),
                  ],
                ),
                for (final t in owned) _heroRow(t),
                const SizedBox(height: 14),
                Text(tr('deck_tactics_count', {'n': tacticCount, 'max': maxTactics, 'min': minTactics}),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                for (final c in cardList) _tacticRow(c),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
