import 'package:flutter/material.dart';

import '../models/units.dart';
import '../strings.dart';
import 'icons.dart';
import 'theme.dart';

Color rarityColor(int r) => switch (r) {
      1 => const Color(0xFF8A7B5E),
      2 => const Color(0xFF2F7DD1),
      3 => const Color(0xFF7B3FA0),
      _ => Pal.gold,
    };

String rarityName(int r) => tr('rarity_$r');

/// Character picture (optional `assets/units/<id>.png`), icon otherwise.
Widget heroPortrait(UnitType t, double size) {
  final col = rarityColor(t.rarity);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: col.withAlpha(40),
      border: Border.all(color: col, width: 2),
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/units/${t.id}.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(typeIcon(t), color: col, size: size * 0.5),
      ),
    ),
  );
}

Widget _stat(String label, Object value, {Color? color}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color ?? Pal.ink)),
        Text(label, style: const TextStyle(fontSize: 9, color: Pal.bronze, fontWeight: FontWeight.bold)),
      ],
    );

/// Small card for grids (collection, shop).
class HeroTile extends StatelessWidget {
  const HeroTile({super.key, required this.type, this.owned, this.onTap, this.footer, this.dimLocked = true});
  final UnitType type;
  final int? owned; // null = do not show; 0 = locked
  final VoidCallback? onTap;
  final Widget? footer;
  final bool dimLocked;

  @override
  Widget build(BuildContext context) {
    final col = rarityColor(type.rarity);
    final locked = owned == 0;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: (locked && dimLocked) ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Pal.parchment, Color.lerp(Pal.parchment, col, 0.10)!],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: col, width: 2.5),
            boxShadow: [BoxShadow(color: col.withAlpha(35), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(8)),
                    child: Text(rarityName(type.rarity).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  if (owned != null)
                    locked
                        ? const Icon(Icons.lock, size: 14, color: Pal.bronze)
                        : Text('×$owned', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              heroPortrait(type, 54),
              const SizedBox(height: 6),
              Text(type.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(type.title,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Pal.bronze, fontStyle: FontStyle.italic)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat(tr('stat_atk'), type.attack, color: Pal.attack),
                  _stat(tr('stat_def'), type.defense, color: Pal.place),
                  _stat(tr('stat_hp'), type.hp, color: Pal.green),
                  _stat(tr('stat_move'), type.move),
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 6), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full card: every stat, attack pattern, abilities, story.
class HeroDetail extends StatelessWidget {
  const HeroDetail({super.key, required this.type, this.owned});
  final UnitType type;
  final int? owned;

  @override
  Widget build(BuildContext context) {
    final col = rarityColor(type.rarity);
    final abil = type.abilities.where((a) => a != type.specialAbility).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Pal.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              heroPortrait(type, 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                    Text(type.title,
                        style: const TextStyle(color: Pal.bronze, fontStyle: FontStyle.italic, fontSize: 13)),
                    Text(
                      '${rarityName(type.rarity)}${owned != null ? '  ·  ×$owned' : ''}',
                      style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 14,
            runSpacing: 8,
            children: [
              _stat(tr('stat_atk_long'), type.attack, color: Pal.attack),
              _stat(tr('stat_def_long'), type.defense, color: Pal.place),
              _stat(tr('stat_hp_long'), type.hp, color: Pal.green),
              _stat(tr('stat_move_long'), type.move),
              _stat(tr('stat_vision_long'), type.vision),
              _stat(tr('stat_regen_long'), type.regen, color: Pal.move),
            ],
          ),
          const SizedBox(height: 10),
          Text('${tr('stat_pattern')} : ${patternText(type)}', style: const TextStyle(fontSize: 13)),
          Text('${tr('stat_class')} : ${tr('unit_${type.troopRole}')}', style: const TextStyle(fontSize: 13)),
          if (abil.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(abil.join(' · '),
                  style: const TextStyle(fontSize: 13, color: Pal.green, fontWeight: FontWeight.w600)),
            ),
          if (type.specialAbility.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: col.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: col.withAlpha(120)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, color: col, size: 19),
                  const SizedBox(width: 8),
                  Expanded(child: Text(type.specialAbility,
                    style: TextStyle(fontSize: 13, height: 1.25, color: col, fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(type.description, style: const TextStyle(fontSize: 13, height: 1.3)),
        ],
      ),
    );
  }
}

Future<void> showHeroDialog(BuildContext context, UnitType t, {int? owned, List<Widget> actions = const []}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroDetail(type: t, owned: owned),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: actions),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
