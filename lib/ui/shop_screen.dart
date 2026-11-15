import 'dart:math';

import 'package:flutter/material.dart';

import '../models/units.dart';
import '../profile.dart';
import '../strings.dart';
import 'hero_card.dart';
import 'theme.dart';

/// Pack: price and chance (weights) for rarity 1..4.
class _Pack {
  const _Pack(this.id, this.price, this.weights, this.icon);
  final int id;
  final int price;
  final List<int> weights; // common, rare, epic, legendary
  final IconData icon;
}

const List<_Pack> _packs = [
  _Pack(1, 100, [70, 25, 5, 0], Icons.inventory_2_outlined),
  _Pack(2, 250, [30, 45, 22, 3], Icons.inventory_2),
  _Pack(3, 600, [0, 40, 45, 15], Icons.workspace_premium),
];

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Random _rng = Random();

  UnitType _draw(_Pack p) {
    final total = p.weights.fold(0, (a, b) => a + b);
    var roll = _rng.nextInt(total);
    var rarity = 1;
    for (var i = 0; i < p.weights.length; i++) {
      if (roll < p.weights[i]) {
        rarity = i + 1;
        break;
      }
      roll -= p.weights[i];
    }
    final pool = heroTypes.where((h) => h.rarity == rarity).toList();
    return pool[_rng.nextInt(pool.length)];
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _openPack(_Pack p) async {
    if (Profile.gold < p.price) {
      _toast(tr('shop_need_gold'));
      return;
    }
    Profile.gold -= p.price;
    final hero = _draw(p);
    final dup = Profile.addCard(hero.id);
    setState(() {});
    await showHeroDialog(
      context,
      hero,
      owned: Profile.copiesOf(hero.id),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Pal.indigo, borderRadius: BorderRadius.circular(10)),
          child: Text(
            dup ? tr('pack_dup', {'n': Profile.copiesOf(hero.id)}) : tr('pack_new'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _buy(UnitType t) {
    if (!Profile.buy(t.id, t.price)) {
      _toast(tr('shop_need_gold'));
      return;
    }
    setState(() {});
    _toast(tr('shop_bought', {'name': t.name}));
  }

  Widget _gold() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Pal.indigo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Pal.gold, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on, color: Pal.gold, size: 20),
          const SizedBox(width: 6),
          Text('${Profile.gold}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
      );

  Widget _packCard(_Pack p) {
    final w = p.weights;
    final total = w.fold(0, (a, b) => a + b);
    final odds = [
      for (var i = 0; i < w.length; i++)
        if (w[i] > 0) '${rarityName(i + 1)} ${(w[i] * 100 / total).round()}%'
    ].join(' · ');
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
            Icon(p.icon, size: 40, color: Pal.bronze),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('shop_pack_${p.id}'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(odds, style: const TextStyle(fontSize: 11, color: Pal.bronze)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: Profile.gold >= p.price ? () => _openPack(p) : null,
              icon: const Icon(Icons.monetization_on, size: 18),
              label: Text('${p.price}'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...heroTypes]..sort((a, b) => a.rarity.compareTo(b.rarity));
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('shop_title')),
        actions: [Center(child: _gold()), const SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(tr('shop_packs'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                for (final p in _packs) _packCard(p),
                const SizedBox(height: 12),
                Text(tr('shop_cards'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.66,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final t = sorted[i];
                    final can = Profile.gold >= t.price;
                    return HeroTile(
                      type: t,
                      owned: Profile.copiesOf(t.id),
                      dimLocked: false,
                      onTap: () => showHeroDialog(context, t, owned: Profile.copiesOf(t.id)),
                      footer: SizedBox(
                        height: 30,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: can ? () => _buy(t) : null,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.monetization_on, size: 14),
                            const SizedBox(width: 4),
                            Text('${t.price}'),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
