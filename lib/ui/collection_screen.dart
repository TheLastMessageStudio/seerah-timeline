import 'package:flutter/material.dart';

import '../models/cards.dart';
import '../models/units.dart';
import '../profile.dart';
import '../strings.dart';
import 'deck_editor_screen.dart';
import 'hero_card.dart';
import 'icons.dart';
import 'theme.dart';

/// Your cards (heroes and tactics) and your custom decks.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  Future<void> _edit(CustomDeck? d) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DeckEditorScreen(deck: d)),
    );
    if (mounted) setState(() {});
  }

  Widget _heroes() {
    final sorted = [...heroTypes]..sort((a, b) {
        final oa = Profile.copiesOf(a.id) > 0 ? 0 : 1;
        final ob = Profile.copiesOf(b.id) > 0 ? 0 : 1;
        if (oa != ob) return oa.compareTo(ob);
        return b.rarity.compareTo(a.rarity);
      });
    final have = heroTypes.where((h) => Profile.copiesOf(h.id) > 0).length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(tr('col_progress', {'n': have, 'total': heroTypes.length}),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 0.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final t = sorted[i];
            final n = Profile.copiesOf(t.id);
            return HeroTile(
              type: t,
              owned: n,
              onTap: () => showHeroDialog(context, t, owned: n),
            );
          },
        ),
      ],
    );
  }

  Widget _tactics() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(tr('col_tactics_note'), style: const TextStyle(color: Pal.bronze)),
        const SizedBox(height: 8),
        for (final c in cardList)
          Card(
            color: Pal.parchment,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Pal.green,
                child: Text('${c.cost}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.description),
              trailing: Icon(cardIcon(c), color: Pal.bronze),
            ),
          ),
      ],
    );
  }

  Widget _deckCard({required String name, required String info, VoidCallback? onEdit, VoidCallback? onDelete}) {
    return Card(
      color: Pal.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Pal.bronze, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Pal.green)),
                  const SizedBox(height: 4),
                  Text(info, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (onEdit != null) IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Pal.bronze)),
            if (onDelete != null) IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Pal.enemy)),
          ],
        ),
      ),
    );
  }

  String _armyInfo(List<String> army, int tactics) {
    final counts = <String, int>{};
    for (final i in army) {
      counts[i] = (counts[i] ?? 0) + 1;
    }
    final names = counts.entries
        .where((e) => unitById.containsKey(e.key))
        .map((e) => e.value > 1 ? '${unitById[e.key]!.name} ×${e.value}' : unitById[e.key]!.name)
        .join(', ');
    return '${tr('deck_units', {'n': army.length})} · ${tr('deck_tactics', {'n': tactics})}\n$names';
  }

  Widget _decks() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(tr('col_my_decks'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        if (Profile.customDecks.isEmpty) Text(tr('col_no_decks')),
        for (final d in Profile.customDecks)
          _deckCard(
            name: d.name,
            info: _armyInfo(d.army, d.cards.length),
            onEdit: () => _edit(d),
            onDelete: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tr('deck_delete_q', {'name': d.name})),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('btn_cancel'))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('deck_delete'))),
                  ],
                ),
              );
              if (ok == true) setState(() => Profile.removeDeck(d));
            },
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _edit(null),
          icon: const Icon(Icons.add),
          label: Text(tr('deck_new')),
        ),
        const SizedBox(height: 16),
        Text(tr('col_presets'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        for (final d in decks) _deckCard(name: d.name, info: _armyInfo(d.armyIds, d.cardIds.length)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('col_title')),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Pal.gold,
            tabs: [
              Tab(text: tr('col_tab_heroes')),
              Tab(text: tr('col_tab_tactics')),
              Tab(text: tr('col_tab_decks')),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: TabBarView(children: [_heroes(), _tactics(), _decks()]),
            ),
          ),
        ),
      ),
    );
  }
}
