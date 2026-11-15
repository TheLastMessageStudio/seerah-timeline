import '../strings.dart';
import 'units.dart';

enum CardEffect {
  heal, shield, fortify, rally, march, recon, energy,
  drums, sabotage, sandstorm, ambush, reinforce, damage, rush,
}

enum TargetKind { none, friendlyUnit, enemyUnit, ownCity, anyCell }

/// Tactical card. Soldiers are NOT cards: armies are placed before the battle.
class CardDef {
  const CardDef({
    required this.id,
    required this.cost,
    required this.effect,
    this.target = TargetKind.none,
    this.value = 0,
    this.unitId = '',
  });

  final String id;
  final int cost;
  final CardEffect effect;
  final TargetKind target;
  final int value;
  final String unitId; // reinforcement unit type

  String get name => tr('card_$id');
  String get description => tr('carddesc_$id');
}

const List<CardDef> cardList = [
  CardDef(id: 'shieldwall', cost: 1, effect: CardEffect.shield, target: TargetKind.friendlyUnit, value: 2),
  CardDef(id: 'fortify', cost: 1, effect: CardEffect.fortify, target: TargetKind.friendlyUnit, value: 1),
  CardDef(id: 'waterskins', cost: 1, effect: CardEffect.heal, target: TargetKind.friendlyUnit, value: 3),
  CardDef(id: 'rally', cost: 2, effect: CardEffect.rally, target: TargetKind.friendlyUnit, value: 1),
  CardDef(id: 'march', cost: 1, effect: CardEffect.march, target: TargetKind.friendlyUnit),
  CardDef(id: 'recon', cost: 1, effect: CardEffect.recon, target: TargetKind.anyCell),
  CardDef(id: 'cache', cost: 1, effect: CardEffect.energy, value: 2),
  CardDef(id: 'drums', cost: 1, effect: CardEffect.drums, target: TargetKind.enemyUnit),
  CardDef(id: 'sabotage', cost: 1, effect: CardEffect.sabotage, target: TargetKind.enemyUnit),
  CardDef(id: 'sandstorm', cost: 2, effect: CardEffect.sandstorm),
  CardDef(id: 'ambush', cost: 1, effect: CardEffect.ambush, target: TargetKind.friendlyUnit),
  CardDef(id: 'arrows', cost: 2, effect: CardEffect.damage, target: TargetKind.enemyUnit, value: 2),
  CardDef(id: 'charge', cost: 2, effect: CardEffect.rush, target: TargetKind.friendlyUnit),
  CardDef(id: 'levy', cost: 2, effect: CardEffect.reinforce, target: TargetKind.ownCity, unitId: 'spearmen'),
  CardDef(id: 'reserve', cost: 3, effect: CardEffect.reinforce, target: TargetKind.ownCity, unitId: 'rider'),
];

final Map<String, CardDef> allCards = {for (final c in cardList) c.id: c};

class DeckDef {
  const DeckDef(this.id, this.cardIds, this.armyIds, {this.label = ''});
  final String id;
  final List<String> cardIds;
  final List<String> armyIds;
  final String label; // custom decks: the name chosen by the player

  bool get isCustom => label.isNotEmpty;
  String get name => isCustom ? label : tr('deck_${id}_name');
  String get style => isCustom ? tr('deck_custom_style') : tr('deck_${id}_style');
  String get description => isCustom ? tr('deck_custom_desc') : tr('deck_${id}_desc');

  List<CardDef> build() => [for (final i in cardIds) allCards[i]!];
  List<UnitType> army() => [for (final i in armyIds) unitById[i]!];

  List<CardDef> get featured {
    final seen = <String>{};
    return [
      for (final i in cardIds)
        if (seen.add(i)) allCards[i]!
    ].take(4).toList();
  }

  /// e.g. "Spearmen x3, Archers x2"
  String get armySummary {
    final counts = <String, int>{};
    for (final i in armyIds) {
      counts[i] = (counts[i] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => '${unitById[e.key]!.name} ×${e.value}')
        .join(', ');
  }
}

const List<DeckDef> decks = [
  DeckDef(
    'a',
    [
      'shieldwall', 'shieldwall', 'fortify', 'fortify', 'waterskins', 'waterskins',
      'rally', 'levy', 'levy', 'sandstorm', 'drums', 'recon', 'cache', 'arrows', 'arrows',
    ],
    ['talha', 'salman', 'umar', 'hamza', 'barra', 'safiyya', 'saad', 'musab', 'rufayda', 'nusayba'],
  ),
  DeckDef(
    'b',
    [
      'march', 'march', 'recon', 'recon', 'ambush', 'ambush', 'sabotage', 'sabotage',
      'reserve', 'reserve', 'cache', 'sandstorm', 'drums', 'charge', 'charge', 'arrows',
    ],
    ['khalid', 'zubayr', 'miqdad', 'khawla', 'amr', 'uqba', 'baybars', 'bilal', 'jafar', 'tariq'],
  ),
];

/// Card limits for custom decks.
const int minArmy = 5;
const int maxArmy = 10;
const int minTactics = 10;
const int maxTactics = 16;
const int maxTacticCopies = 2;

/// Heroes you own when you start (everything else comes from the shop).
const Map<String, int> starterCards = {
  'barra': 2, 'bilal': 2, 'salman': 2, 'miqdad': 2, 'nusayba': 2, 'rufayda': 2,
  'musab': 1, 'safiyya': 1, 'amr': 1, 'tariq': 1,
};

/// Default tactic cards for a new custom deck.
const List<String> defaultTactics = [
  'shieldwall', 'shieldwall', 'fortify', 'waterskins', 'waterskins', 'rally',
  'march', 'recon', 'cache', 'drums', 'arrows', 'charge', 'levy', 'ambush',
];
