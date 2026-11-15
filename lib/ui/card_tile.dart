import 'package:flutter/material.dart';

import '../models/cards.dart';
import 'icons.dart';
import 'theme.dart';

/// A tactical card in the player's hand.
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final CardDef card;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 104,
        height: 132,
        margin: EdgeInsets.fromLTRB(4, selected ? 0 : 8, 4, selected ? 8 : 0),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled ? Pal.parchment : const Color(0xFFD8CDB3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Pal.gold : Pal.bronze,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Colors.black38, blurRadius: 6)]
              : null,
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Pal.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${card.cost}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(cardIcon(card), size: 20, color: Pal.bronze),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                card.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  card.description,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 10, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
