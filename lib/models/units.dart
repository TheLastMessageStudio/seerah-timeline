import 'dart:math';

import '../strings.dart';
import 'battlefield.dart';
import 'side.dart';

/// Shape of an attack pattern (like chess pieces).
enum AtkShape { orth, diag, area, ring, knight, none }

class UnitType {
  const UnitType({
    required this.id,
    required this.move,
    required this.attack,
    required this.defense,
    required this.hp,
    required this.shape,
    required this.minR,
    required this.maxR,
    this.vision = 3,
    this.ranged = false,
    this.duneRider = false,
    this.noMountain = false,
    this.aura = false,
    this.healer = false,
    this.role = '',
    this.regen = 0,
    this.energy = 0,
    this.rarity = 0,
    this.heroName = '',
    this.titleFr = '',
    this.titleEn = '',
    this.bioFr = '',
    this.bioEn = '',
    this.specialFr = '',
    this.specialEn = '',
    this.meleeBonus = 0,
    this.defenseAura = false,
    this.rangeBonus = 0,
    this.flankBonus = 0,
  });

  final String id;
  final int move;
  final int attack;
  final int defense;
  final int hp;
  final AtkShape shape;
  final int minR;
  final int maxR;
  final int vision;
  final bool ranged; // gets elevation range bonus
  final bool duneRider; // dunes cost 1 and give no penalty
  final bool noMountain; // cannot enter mountains
  final bool aura; // +1 attack to adjacent allies
  final bool healer; // heals adjacent allies at turn start

  /// Troop class: same-role units side by side form a troop (default: [id]).
  final String role;
  final int regen; // HP recovered by the unit itself at the start of its turn
  final int energy; // extra energy for its owner at the start of the turn
  final int rarity; // 0 = generic soldier, 1 common .. 4 legendary
  final String heroName;
  final String titleFr;
  final String titleEn;
  final String bioFr;
  final String bioEn;
  /// Signature passive shown on the hero card and applied by the battle engine.
  final String specialFr;
  final String specialEn;
  final int meleeBonus; // extra damage dealt to adjacent targets
  final bool defenseAura; // adjacent allies gain +1 defense
  final int rangeBonus; // extra range for ranged attacks
  final int flankBonus; // extra damage when a flank is created

  String get troopRole => role.isEmpty ? id : role;
  bool get isHero => rarity > 0;
  int get price => const [0, 80, 200, 450, 900][rarity];
  String get title => currentLanguage == 'fr' ? titleFr : titleEn;

  String get name => heroName.isNotEmpty ? heroName : tr('unit_$id');
  bool get named => heroName.isNotEmpty;
  String get description => named
      ? (currentLanguage == 'fr' ? bioFr : bioEn)
      : tr('unitdesc_$id');

  /// Short list of special abilities (already translated).
  List<String> get abilities => [
        if (aura) tr('abil_aura'),
        if (healer) tr('abil_healer'),
        if (regen > 0) tr('abil_regen', {'n': regen}),
        if (energy > 0) tr('abil_energy', {'n': energy}),
        if (duneRider) tr('abil_dune'),
        if (noMountain) tr('abil_nomountain'),
        if (ranged) tr('abil_ranged'),
        if (specialAbility.isNotEmpty) specialAbility,
      ];

  String get specialAbility => currentLanguage == 'fr' ? specialFr : specialEn;

  /// Can this attack pattern hit a target at offset ([dx],[dy])?
  /// [bonus] extends the maximum range of ranged units.
  bool canHit(int dx, int dy, {int bonus = 0}) {
    final ax = dx.abs();
    final ay = dy.abs();
    final hi = maxR + (ranged ? bonus : 0);
    switch (shape) {
      case AtkShape.none:
        return false;
      case AtkShape.orth:
        if (ax != 0 && ay != 0) return false;
        final d = ax + ay;
        return d >= minR && d <= hi;
      case AtkShape.diag:
        if (ax != ay) return false;
        return ax >= minR && ax <= hi;
      case AtkShape.area:
        final d = ax + ay;
        return d >= minR && d <= hi;
      case AtkShape.ring:
        final d = max(ax, ay);
        return d >= minR && d <= hi;
      case AtkShape.knight:
        return (ax == 1 && ay == 2) || (ax == 2 && ay == 1);
    }
  }
}

const List<UnitType> unitTypes = [
  UnitType(id: 'spearmen', move: 3, attack: 3, defense: 1, hp: 5, shape: AtkShape.orth, minR: 1, maxR: 2),
  UnitType(id: 'swordsman', move: 3, attack: 4, defense: 1, hp: 5, shape: AtkShape.ring, minR: 1, maxR: 1),
  UnitType(id: 'archer', move: 3, attack: 3, defense: 0, hp: 3, shape: AtkShape.area, minR: 2, maxR: 3, vision: 4, ranged: true),
  UnitType(id: 'skirmisher', move: 4, attack: 3, defense: 0, hp: 3, shape: AtkShape.diag, minR: 1, maxR: 2, ranged: true),
  UnitType(id: 'guard', move: 2, attack: 2, defense: 2, hp: 7, shape: AtkShape.orth, minR: 1, maxR: 1),
  UnitType(id: 'scout', move: 6, attack: 2, defense: 0, hp: 3, shape: AtkShape.ring, minR: 1, maxR: 1, vision: 7),
  UnitType(id: 'rider', move: 6, attack: 4, defense: 0, hp: 4, shape: AtkShape.knight, minR: 1, maxR: 1, vision: 4, noMountain: true),
  UnitType(id: 'camel', move: 5, attack: 3, defense: 0, hp: 5, shape: AtkShape.ring, minR: 1, maxR: 1, vision: 4, noMountain: true, duneRider: true),
  UnitType(id: 'standard', move: 3, attack: 1, defense: 1, hp: 4, shape: AtkShape.orth, minR: 1, maxR: 1, aura: true),
  UnitType(id: 'healer', move: 3, attack: 1, defense: 0, hp: 3, shape: AtkShape.orth, minR: 1, maxR: 1, healer: true),
  UnitType(id: 'messenger', move: 5, attack: 0, defense: 0, hp: 3, shape: AtkShape.none, minR: 1, maxR: 1, vision: 4),
];


/// Historical heroes: the collectible unit cards (rarity 1 common .. 4 legendary).
/// `role` = troop class (same-role heroes side by side move as a troop).
const List<UnitType> heroTypes = [
  // ---------------------------------------------------------------- legendary
  UnitType(id: 'khalid', heroName: 'Khalid ibn al-Walid', rarity: 4, role: 'rider',
      move: 7, attack: 6, defense: 1, hp: 6, shape: AtkShape.knight, minR: 1, maxR: 1, vision: 5, noMountain: true,
      titleFr: 'Sayf Allah, l\'Épée d\'Allah', titleEn: 'Sayf Allah, the Sword of Allah',
      flankBonus: 1, specialFr: 'Charge éclair : +1 dégât lors d\'une attaque de flanc.', specialEn: 'Swift charge: +1 damage when flanking.',
      bioFr: 'Commandant de génie, vainqueur des guerres de la Ridda et de Yarmouk.',
      bioEn: 'Brilliant commander, victorious in the Ridda wars and at Yarmouk.'),
  UnitType(id: 'ali', heroName: 'Ali ibn Abi Talib', rarity: 4, role: 'swordsman', regen: 1,
      move: 3, attack: 6, defense: 2, hp: 8, shape: AtkShape.ring, minR: 1, maxR: 2,
      titleFr: 'Asad Allah, le Lion d\'Allah', titleEn: 'Asad Allah, the Lion of Allah',
      meleeBonus: 1, specialFr: 'Maître du duel : +1 dégât au corps à corps.', specialEn: 'Duel master: +1 damage in melee.',
      bioFr: 'Cousin et gendre du Prophète ﷺ, quatrième calife, héros de Badr et de Khaybar.',
      bioEn: 'Cousin and son-in-law of the Prophet ﷺ, fourth caliph, hero of Badr and Khaybar.'),
  UnitType(id: 'umar', heroName: 'Umar ibn al-Khattab', rarity: 4, role: 'guard', aura: true,
      move: 3, attack: 3, defense: 3, hp: 8, shape: AtkShape.orth, minR: 1, maxR: 1, vision: 4,
      titleFr: 'al-Faruq', titleEn: 'al-Faruq',
      defenseAura: true, specialFr: 'Commandement ferme : les alliés adjacents gagnent +1 défense.', specialEn: 'Steadfast command: adjacent allies gain +1 defense.',
      bioFr: 'Deuxième calife, il organisa l\'État et les armées des grandes conquêtes.',
      bioEn: 'Second caliph, he organised the state and the armies of the great conquests.'),
  UnitType(id: 'salahuddin', heroName: 'Salah ad-Din al-Ayyubi', rarity: 4, role: 'rider', aura: true,
      move: 6, attack: 5, defense: 1, hp: 7, shape: AtkShape.knight, minR: 1, maxR: 1, vision: 5, noMountain: true,
      titleFr: 'Vainqueur de Hattin', titleEn: 'Victor of Hattin',
      defenseAura: true, flankBonus: 1, specialFr: 'Manœuvre et discipline : +1 défense aux alliés adjacents et +1 dégât de flanc.', specialEn: 'Maneuver and discipline: adjacent allies gain +1 defense and flanks deal +1 damage.',
      bioFr: 'Sultan qui reprit Jérusalem en 1187 après la bataille de Hattin.',
      bioEn: 'Sultan who retook Jerusalem in 1187 after the battle of Hattin.'),
  UnitType(id: 'fatih', heroName: 'Mehmed al-Fatih', rarity: 4, role: 'archer', ranged: true,
      move: 2, attack: 6, defense: 0, hp: 5, shape: AtkShape.area, minR: 2, maxR: 4, vision: 4,
      titleFr: 'Conquérant de Constantinople', titleEn: 'Conqueror of Constantinople',
      rangeBonus: 1, specialFr: 'Artillerie de siège : +1 portée aux attaques à distance.', specialEn: 'Siege artillery: +1 range to ranged attacks.',
      bioFr: 'Sultan ottoman qui prit Constantinople en 1453 grâce à son artillerie.',
      bioEn: 'Ottoman sultan who took Constantinople in 1453 with his artillery.'),
  // --------------------------------------------------------------------- epic
  UnitType(id: 'hamza', heroName: 'Hamza ibn Abd al-Muttalib', rarity: 3, role: 'swordsman',
      move: 3, attack: 5, defense: 1, hp: 7, shape: AtkShape.ring, minR: 1, maxR: 1,
      titleFr: 'Sayyid al-Shuhada', titleEn: 'Sayyid al-Shuhada',
      meleeBonus: 1, specialFr: 'Lion de Badr : +1 dégât au corps à corps.', specialEn: 'Lion of Badr: +1 melee damage.',
      bioFr: 'Oncle du Prophète ﷺ, lion de Badr, tombé en martyr à Uhud.',
      bioEn: 'Uncle of the Prophet ﷺ, lion of Badr, martyred at Uhud.'),
  UnitType(id: 'abubakr', heroName: 'Abu Bakr as-Siddiq', rarity: 3, role: 'healer', aura: true, healer: true, regen: 1,
      move: 3, attack: 1, defense: 1, hp: 6, shape: AtkShape.orth, minR: 1, maxR: 1,
      titleFr: 'as-Siddiq', titleEn: 'as-Siddiq',
      bioFr: 'Premier calife, compagnon de la grotte, il rassembla la communauté.',
      bioEn: 'First caliph, companion of the cave, he united the community.'),
  UnitType(id: 'uthman', heroName: 'Uthman ibn Affan', rarity: 3, role: 'standard', energy: 1,
      move: 3, attack: 1, defense: 1, hp: 5, shape: AtkShape.orth, minR: 1, maxR: 1,
      titleFr: 'Dhu al-Nurayn', titleEn: 'Dhu al-Nurayn',
      bioFr: 'Troisième calife, il finança en grande partie l\'armée de Tabuk.',
      bioEn: 'Third caliph, he largely funded the army of Tabuk.'),
  UnitType(id: 'saad', heroName: 'Sa\'d ibn Abi Waqqas', rarity: 3, role: 'archer', ranged: true,
      move: 3, attack: 4, defense: 0, hp: 4, shape: AtkShape.area, minR: 2, maxR: 4, vision: 5,
      titleFr: 'Premier archer de l\'Islam', titleEn: 'First archer of Islam',
      rangeBonus: 1, specialFr: 'Tireur d\'élite : +1 portée aux attaques à distance.', specialEn: 'Master archer: +1 range to ranged attacks.',
      bioFr: 'Il tira la première flèche pour la cause d\'Allah et mena la victoire de Qadisiyya.',
      bioEn: 'He shot the first arrow for the cause of Allah and led the victory of Qadisiyya.'),
  UnitType(id: 'zubayr', heroName: 'az-Zubayr ibn al-Awwam', rarity: 3, role: 'rider',
      move: 6, attack: 5, defense: 0, hp: 5, shape: AtkShape.knight, minR: 1, maxR: 1, vision: 4, noMountain: true,
      titleFr: 'Hawari du Prophète ﷺ', titleEn: 'Disciple of the Prophet ﷺ',
      flankBonus: 1, specialFr: 'Cavalier intrépide : +1 dégât lors d\'une attaque de flanc.', specialEn: 'Fearless horseman: +1 damage when flanking.',
      bioFr: 'Cavalier intrépide de Badr, Uhud, du Fossé et de Yarmouk.',
      bioEn: 'Fearless horseman of Badr, Uhud, the Trench and Yarmouk.'),
  UnitType(id: 'talha', heroName: 'Talha ibn Ubaydullah', rarity: 3, role: 'guard',
      move: 2, attack: 3, defense: 3, hp: 8, shape: AtkShape.orth, minR: 1, maxR: 1,
      titleFr: 'Talha le Généreux', titleEn: 'Talha the Generous',
      defenseAura: true, specialFr: 'Bouclier des compagnons : les alliés adjacents gagnent +1 défense.', specialEn: 'Shield of the companions: adjacent allies gain +1 defense.',
      bioFr: 'À Uhud, il couvrit le Prophète ﷺ de son corps.',
      bioEn: 'At Uhud, he shielded the Prophet ﷺ with his own body.'),
  UnitType(id: 'abuubayda', heroName: 'Abu Ubayda ibn al-Jarrah', rarity: 3, role: 'standard', aura: true,
      move: 3, attack: 2, defense: 2, hp: 6, shape: AtkShape.orth, minR: 1, maxR: 1, vision: 4,
      titleFr: 'Amin al-Umma', titleEn: 'Amin al-Umma',
      defenseAura: true, specialFr: 'Gardien de confiance : les alliés adjacents gagnent +1 défense.', specialEn: 'Trusted guardian: adjacent allies gain +1 defense.',
      bioFr: 'L\'homme de confiance de la communauté, conquérant du Cham.',
      bioEn: 'The trustworthy one of the community, conqueror of the Levant.'),
  UnitType(id: 'baybars', heroName: 'Baybars', rarity: 3, role: 'skirmisher', ranged: true,
      move: 5, attack: 4, defense: 0, hp: 4, shape: AtkShape.diag, minR: 1, maxR: 3, vision: 4,
      titleFr: 'Vainqueur d\'Aïn Jalut', titleEn: 'Victor of Ain Jalut',
      rangeBonus: 1, specialFr: 'Tir monté : +1 portée aux attaques à distance.', specialEn: 'Mounted marksmanship: +1 range to ranged attacks.',
      bioFr: 'Chef mamelouk, il joua un rôle décisif contre les Mongols en 1260.',
      bioEn: 'Mamluk leader, decisive against the Mongols in 1260.'),
  UnitType(id: 'jafar', heroName: 'Jafar ibn Abi Talib', rarity: 3, role: 'swordsman',
      move: 5, attack: 4, defense: 1, hp: 5, shape: AtkShape.ring, minR: 1, maxR: 1, vision: 4,
      titleFr: 'at-Tayyar', titleEn: 'at-Tayyar',
      meleeBonus: 1, specialFr: 'Porte-étendard héroïque : +1 dégât au corps à corps.', specialEn: 'Heroic standard-bearer: +1 melee damage.',
      bioFr: 'Commandant à Mu\'tah, il tint l\'étendard jusqu\'au bout.',
      bioEn: 'Commander at Mu\'tah, he held the banner to the very end.'),
  // --------------------------------------------------------------------- rare
  UnitType(id: 'amr', heroName: 'Amr ibn al-As', rarity: 2, role: 'camel', duneRider: true, noMountain: true,
      move: 5, attack: 4, defense: 0, hp: 5, shape: AtkShape.ring, minR: 1, maxR: 1, vision: 4,
      titleFr: 'Conquérant de l\'Égypte', titleEn: 'Conqueror of Egypt',
      specialFr: 'Maître du désert : traverse les dunes sans pénalité.', specialEn: 'Desert master: crosses dunes without a movement penalty.',
      bioFr: 'Stratège qui mena la conquête de l\'Égypte vers 640.',
      bioEn: 'Strategist who led the conquest of Egypt around 640.'),
  UnitType(id: 'tariq', heroName: 'Tariq ibn Ziyad', rarity: 2, role: 'swordsman',
      move: 4, attack: 4, defense: 1, hp: 6, shape: AtkShape.ring, minR: 1, maxR: 1, vision: 4,
      titleFr: 'Conquérant d\'al-Andalus', titleEn: 'Conqueror of al-Andalus',
      meleeBonus: 1, specialFr: 'Détermination : +1 dégât au corps à corps.', specialEn: 'Determination: +1 melee damage.',
      bioFr: 'Il franchit le détroit en 711 et ouvrit la conquête de la péninsule ibérique.',
      bioEn: 'He crossed the strait in 711 and opened the conquest of Iberia.'),
  UnitType(id: 'musab', heroName: 'Mus\'ab ibn Umayr', rarity: 2, role: 'standard', aura: true,
      move: 3, attack: 1, defense: 1, hp: 5, shape: AtkShape.orth, minR: 1, maxR: 1,
      titleFr: 'Porte-étendard d\'Uhud', titleEn: 'Standard bearer of Uhud',
      defenseAura: true, specialFr: 'Étendard rassembleur : les alliés adjacents gagnent +1 défense.', specialEn: 'Rallying standard: adjacent allies gain +1 defense.',
      bioFr: 'Premier envoyé à Médine, il porta l\'étendard à Badr et à Uhud.',
      bioEn: 'First envoy to Madinah, he carried the banner at Badr and Uhud.'),
  UnitType(id: 'abudujana', heroName: 'Abu Dujana', rarity: 2, role: 'swordsman',
      move: 3, attack: 5, defense: 0, hp: 5, shape: AtkShape.ring, minR: 1, maxR: 1,
      titleFr: 'Le turban rouge', titleEn: 'The red turban',
      meleeBonus: 1, specialFr: 'Assaut déterminé : +1 dégât au corps à corps.', specialEn: 'Resolute assault: +1 melee damage.',
      bioFr: 'À Uhud, il reçut l\'épée du Prophète ﷺ et combattit avec acharnement.',
      bioEn: 'At Uhud he received the sword of the Prophet ﷺ and fought fiercely.'),
  UnitType(id: 'zayd', heroName: 'Zayd ibn Haritha', rarity: 2, role: 'standard', aura: true,
      move: 3, attack: 2, defense: 1, hp: 5, shape: AtkShape.orth, minR: 1, maxR: 1,
      titleFr: 'Chef de Mu\'tah', titleEn: 'Leader at Mu\'tah',
      defenseAura: true, specialFr: 'Commandement : les alliés adjacents gagnent +1 défense.', specialEn: 'Command: adjacent allies gain +1 defense.',
      bioFr: 'Compagnon aimé du Prophète ﷺ, commandant de plusieurs expéditions.',
      bioEn: 'Beloved companion of the Prophet ﷺ, commander of several expeditions.'),
  UnitType(id: 'khawla', heroName: 'Khawla bint al-Azwar', rarity: 2, role: 'rider',
      move: 6, attack: 4, defense: 1, hp: 5, shape: AtkShape.knight, minR: 1, maxR: 1, vision: 4, noMountain: true,
      titleFr: 'La cavalière du Cham', titleEn: 'Horsewoman of the Levant',
      flankBonus: 1, specialFr: 'Cavalière audacieuse : +1 dégât lors d\'une attaque de flanc.', specialEn: 'Bold horsewoman: +1 damage when flanking.',
      bioFr: 'Guerrière célèbre des récits des conquêtes du Cham (Ajnadayn, Yarmouk).',
      bioEn: 'Famous warrior of the accounts of the conquest of the Levant (Ajnadayn, Yarmouk).'),
  UnitType(id: 'uqba', heroName: 'Uqba ibn Nafi', rarity: 2, role: 'camel', duneRider: true, noMountain: true,
      move: 5, attack: 3, defense: 1, hp: 6, shape: AtkShape.ring, minR: 1, maxR: 1, vision: 5,
      titleFr: 'Fondateur de Kairouan', titleEn: 'Founder of Kairouan',
      flankBonus: 1, specialFr: 'Mobilité du désert : +1 dégât lors d\'une attaque de flanc.', specialEn: 'Desert mobility: +1 damage when flanking.',
      bioFr: 'Explorateur et chef militaire du Maghreb, il fonda Kairouan vers 670.',
      bioEn: 'Explorer and military leader of the Maghreb, he founded Kairouan around 670.'),
  UnitType(id: 'safiyya', heroName: 'Safiyya bint Abd al-Muttalib', rarity: 2, role: 'spearmen', regen: 1,
      move: 3, attack: 3, defense: 1, hp: 5, shape: AtkShape.orth, minR: 1, maxR: 2,
      titleFr: 'Gardienne de Médine', titleEn: 'Guardian of Madinah',
      defenseAura: true, specialFr: 'Protectrice : les alliés adjacents gagnent +1 défense.', specialEn: 'Protector: adjacent allies gain +1 defense.',
      bioFr: 'Tante du Prophète ﷺ, elle protégea les familles pendant la bataille du Fossé.',
      bioEn: 'Aunt of the Prophet ﷺ, she protected the families during the Battle of the Trench.'),
  // ------------------------------------------------------------------- common
  UnitType(id: 'barra', heroName: 'al-Barra ibn Malik', rarity: 1, role: 'spearmen',
      move: 3, attack: 3, defense: 1, hp: 6, shape: AtkShape.orth, minR: 1, maxR: 2,
      titleFr: 'Le lion des batailles', titleEn: 'Lion of the battles',
      bioFr: 'Réputé pour son courage, notamment à la bataille de Yamama.',
      bioEn: 'Famed for his courage, notably at the battle of Yamama.'),
  UnitType(id: 'bilal', heroName: 'Bilal ibn Rabah', rarity: 1, role: 'skirmisher', ranged: true,
      move: 4, attack: 3, defense: 0, hp: 4, shape: AtkShape.diag, minR: 1, maxR: 2,
      titleFr: 'Premier muezzin', titleEn: 'First muezzin',
      bioFr: 'Voix de l\'appel à la prière, il combattit à Badr.',
      bioEn: 'Voice of the call to prayer, he fought at Badr.'),
  UnitType(id: 'salman', heroName: 'Salman al-Farisi', rarity: 1, role: 'guard',
      move: 2, attack: 2, defense: 2, hp: 7, shape: AtkShape.orth, minR: 1, maxR: 1, vision: 4,
      titleFr: 'L\'idée du Fossé', titleEn: 'Mind behind the Trench',
      bioFr: 'Il conseilla de creuser le Khandaq pour défendre Médine.',
      bioEn: 'He advised digging the Khandaq to defend Madinah.'),
  UnitType(id: 'miqdad', heroName: 'al-Miqdad ibn Amr', rarity: 1, role: 'rider',
      move: 6, attack: 4, defense: 0, hp: 4, shape: AtkShape.knight, minR: 1, maxR: 1, vision: 4, noMountain: true,
      titleFr: 'Cavalier de Badr', titleEn: 'Horseman of Badr',
      bioFr: 'L\'un des rares cavaliers musulmans de la bataille de Badr.',
      bioEn: 'One of the few Muslim horsemen at the battle of Badr.'),
  UnitType(id: 'nusayba', heroName: 'Nusayba bint Ka\'b', rarity: 1, role: 'swordsman', regen: 1,
      move: 3, attack: 3, defense: 1, hp: 6, shape: AtkShape.ring, minR: 1, maxR: 1,
      titleFr: 'Umm Umara', titleEn: 'Umm Umara',
      bioFr: 'Elle défendit le Prophète ﷺ à Uhud avec courage.',
      bioEn: 'She bravely defended the Prophet ﷺ at Uhud.'),
  UnitType(id: 'rufayda', heroName: 'Rufayda al-Aslamiyya', rarity: 1, role: 'healer', healer: true,
      move: 3, attack: 1, defense: 0, hp: 3, shape: AtkShape.orth, minR: 1, maxR: 1,
      titleFr: 'Première infirmière', titleEn: 'First nurse',
      bioFr: 'Elle soigna les blessés dans sa tente de soins à Médine.',
      bioEn: 'She treated the wounded in her care tent in Madinah.'),
];

/// Named figures that only appear in story chapters (not collectible).
const List<UnitType> storyUnits = [
  UnitType(id: 'abujahl', heroName: 'Amr ibn Hisham (Abu Jahl)', role: 'guard', aura: true,
      move: 3, attack: 4, defense: 3, hp: 9, shape: AtkShape.orth, minR: 1, maxR: 1, vision: 4,
      titleFr: 'Chef des Quraysh à Badr', titleEn: 'Leader of Quraysh at Badr',
      bioFr: 'Chef de l\'armée mecquoise, il refusa de faire demi-tour après la fuite de la caravane.',
      bioEn: 'Leader of the Meccan army, he refused to turn back after the caravan escaped.'),
  UnitType(id: 'utba', heroName: 'Utba ibn Rabi\'a', role: 'swordsman',
      move: 3, attack: 4, defense: 1, hp: 6, shape: AtkShape.ring, minR: 1, maxR: 1,
      titleFr: 'Champion de Quraysh', titleEn: 'Champion of Quraysh',
      bioFr: 'Noble de Quraysh, sorti en duel au début de la bataille.',
      bioEn: 'Noble of Quraysh, who stepped out for the opening duels.'),
  UnitType(id: 'shayba', heroName: 'Shayba ibn Rabi\'a', role: 'swordsman',
      move: 3, attack: 4, defense: 1, hp: 6, shape: AtkShape.ring, minR: 1, maxR: 1,
      titleFr: 'Champion de Quraysh', titleEn: 'Champion of Quraysh',
      bioFr: 'Frère d\'Utba, il sortit lui aussi en duel.',
      bioEn: 'Brother of Utba, he also stepped out for the duels.'),
  UnitType(id: 'walid', heroName: 'al-Walid ibn Utba', role: 'swordsman',
      move: 4, attack: 4, defense: 1, hp: 5, shape: AtkShape.ring, minR: 1, maxR: 1,
      titleFr: 'Champion de Quraysh', titleEn: 'Champion of Quraysh',
      bioFr: 'Fils d\'Utba, le troisième des champions mecquois.',
      bioEn: 'Son of Utba, the third Meccan champion.'),
  UnitType(id: 'umayya', heroName: 'Umayya ibn Khalaf', role: 'spearmen',
      move: 3, attack: 3, defense: 1, hp: 6, shape: AtkShape.orth, minR: 1, maxR: 2,
      titleFr: 'Ancien maître de Bilal', titleEn: 'Former master of Bilal',
      bioFr: 'Notable de La Mecque qui avait persécuté Bilal.',
      bioEn: 'Notable of Mecca who had persecuted Bilal.'),
  // ------------------------------------------------------------------ Uhud
  UnitType(id: 'abusufyan', heroName: 'Abu Sufyan ibn Harb', role: 'guard', aura: true,
      move: 3, attack: 3, defense: 2, hp: 8, shape: AtkShape.orth, minR: 1, maxR: 1, vision: 4,
      titleFr: 'Chef des Quraysh à Uhud', titleEn: 'Leader of Quraysh at Uhud',
      bioFr: 'Notable de La Mecque qui conduisit l\'armée mecquoise à Uhud pour venger Badr.',
      bioEn: 'Meccan notable who led the Meccan army to Uhud to avenge Badr.'),
  UnitType(id: 'talhatalha', heroName: 'Talha ibn Abi Talha', role: 'standard', aura: true,
      move: 3, attack: 3, defense: 1, hp: 6, shape: AtkShape.orth, minR: 1, maxR: 1,
      titleFr: 'Porte-étendard de Quraysh', titleEn: 'Standard-bearer of Quraysh',
      bioFr: 'Porte-étendard de Quraysh, tombé le premier au combat singulier.',
      bioEn: 'Standard-bearer of Quraysh, who fell first in single combat.'),
  UnitType(id: 'sibaa', heroName: 'Sibaa ibn Abd al-Uzza', role: 'swordsman',
      move: 3, attack: 4, defense: 1, hp: 5, shape: AtkShape.ring, minR: 1, maxR: 1,
      titleFr: 'Champion de Quraysh', titleEn: 'Champion of Quraysh',
      bioFr: 'Il défia les musulmans et tomba sous les coups de Hamza.',
      bioEn: 'He challenged the Muslims and fell to Hamza.'),
  UnitType(id: 'wahshi', heroName: 'Wahshi ibn Harb', role: 'skirmisher', ranged: true,
      move: 4, attack: 4, defense: 0, hp: 3, shape: AtkShape.diag, minR: 1, maxR: 3,
      titleFr: 'Lanceur de javelot', titleEn: 'Javelin thrower',
      bioFr: 'Esclave abyssin, adroit au javelot ; il tua Hamza à Uhud.',
      bioEn: 'An Abyssinian slave skilled with the javelin; he killed Hamza at Uhud.'),
  UnitType(id: 'ikrima', heroName: 'Ikrima ibn Abi Jahl', role: 'rider', noMountain: true,
      move: 6, attack: 4, defense: 0, hp: 4, shape: AtkShape.knight, minR: 1, maxR: 1, vision: 4,
      titleFr: 'Cavalier de l\'aile gauche', titleEn: 'Cavalry of the left wing',
      bioFr: 'Fils d\'Abu Jahl, il commandait la cavalerie de l\'aile gauche mecquoise.',
      bioEn: 'Son of Abu Jahl, he commanded the Meccan left-wing cavalry.'),
  UnitType(id: 'ubayy', heroName: 'Ubayy ibn Khalaf', role: 'spearmen',
      move: 3, attack: 4, defense: 1, hp: 6, shape: AtkShape.orth, minR: 1, maxR: 2,
      titleFr: 'Ennemi juré', titleEn: 'Sworn enemy',
      bioFr: 'Notable mecquois qui avait juré de tuer le Prophète ﷺ ; il fut blessé à Uhud.',
      bioEn: 'Meccan notable who had sworn to kill the Prophet ﷺ; he was wounded at Uhud.'),
  UnitType(id: 'abdullahjubayr', heroName: 'Abdullah ibn Jubayr', role: 'archer', ranged: true,
      move: 3, attack: 4, defense: 0, hp: 4, shape: AtkShape.area, minR: 2, maxR: 3, vision: 4,
      titleFr: 'Chef des archers', titleEn: 'Commander of the archers',
      bioFr: 'Placé sur la colline des archers avec l\'ordre de ne pas quitter son poste.',
      bioEn: 'Posted on the archers\' hill with the order not to leave his position.'),
];

final Map<String, UnitType> unitById = {
  for (final u in [...unitTypes, ...heroTypes, ...storyUnits]) u.id: u
};

class Unit {
  Unit(this.id, this.type, this.side, this.pos) : hp = type.hp;

  final int id;
  final UnitType type;
  final Side side;
  Pos pos;
  int hp;
  bool moved = false;
  bool attacked = false;

  // Buffs: cleared when the owner's next turn starts.
  int tempDef = 0;
  int tempAtk = 0;
  // Permanent buff (Dig In).
  int bonusDef = 0;
  // Debuffs: cleared when the owner's turn ends.
  int weak = 0; // -attack
  int slow = 0; // -movement
  // Hidden in cover: first attack deals +2; enemies see it only when adjacent.
  bool ambush = false;
  // Neutral-city defender (enemy side): never leaves its city, never captures.
  bool garrison = false;
  // Scenario state: waiting enemies and protected enemies (see StoryStart).
  bool hold = false;
  bool guarded = false;
  // Standing march order: the unit advances on its own every turn.
  Pos? dest;

  int hpBonus = 0; // tower mode: extra HP for the AI
  int get maxHp => type.hp + hpBonus;
  String get name => type.name;
  String get label => side == Side.ai ? tr('enemy_prefix', {'name': name}) : name;
}
