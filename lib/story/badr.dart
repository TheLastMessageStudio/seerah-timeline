import '../models/battlefield.dart';
import '../models/cards.dart';
import '../models/game_map.dart';
import '../models/side.dart';
import '../models/story.dart';
import '../models/terrain.dart';
import 'badr_image.dart';
import 'uhud.dart';

/// Badr (17 Ramadan, year 2 AH / March 624). The terrain grid is read from the
/// historical map drawn under the board (north = Madinah side with the Prophet's
/// camp, south = Quraysh camp, Mount al-Asfal to the west, al-Udwat ad-Dunya and
/// al-Udwat al-Quswa to the east, the road along the wadi). Legend:
/// . plains   h hills (slopes)   M mountain (slow, no cavalry)   X cliff (blocked)
/// ~ mud (rain of the night before)   O well   C camp
const int badrCols = 30;
const int badrRows = 21;
const Pos badrKeyWell = Pos(21, 15);

const List<String> _badrGrid = [
  '....hMXMh.h.C..hhMMMMXXXXXXXXX',
  '..hh.hMMh..CCC.hhMMMMXXXXXXMMX',
  '...Mh.hM....C..hhMMMMXXXXXMMMM',
  '..hMM..h........hhMMMXXXXXMMXh',
  '...hXM..h........hMMMXXXXXMMMh',
  '..hhMXM...........MMMMXXXXMMh.',
  '....hMMM...........hhMMMXMMh..',
  '.....MMM.............MMMMMh.hM',
  '...hMhhh.............MMMMhhhMM',
  '...hMMMMh.............hM..hMMM',
  '....hMMMh..............hhhMMMM',
  '...hMMMh.................hMMMM',
  '...hMXMh................hMMMMM',
  '....hXM.~~~~~~~~~.......hMMMMM',
  '....hMM.~~~~~~~~~......hMMMMMM',
  '.....MMh~~~~~~~~~....O.hMMMMMh',
  '.....hMh~~~~~~~~~......hhMhhhh',
  '.....hM.~~~~~~~~~........hhhh.',
  '........~~~~~~~~~....C........',
  '....................CCC.......',
  '.....................C........',
];

/// The road along the wadi (cost 1 per cell), including the Medina branch.
const List<(int, int)> _badrRoads = [(15, 0), (15, 1), (15, 2), (15, 3), (15, 4), (15, 5), (16, 5), (16, 6), (17, 6), (17, 7), (18, 7), (19, 8), (20, 8), (20, 9), (21, 9), (21, 10), (21, 11), (21, 12), (21, 13), (21, 14), (21, 15), (21, 16), (22, 11), (22, 12), (22, 16), (22, 17), (23, 10), (23, 11), (23, 17), (23, 18), (24, 9), (24, 10), (24, 18), (25, 8), (25, 9), (25, 19), (26, 8), (26, 19), (26, 20), (27, 7), (28, 6), (29, 5), (29, 6)];

GameMap buildBadrMap() {
  final t = [
    for (var r = 0; r < badrRows; r++)
      [
        for (var c = 0; c < badrCols; c++)
          switch (_badrGrid[r][c]) {
            'h' => Terrain.hills,
            'M' => Terrain.mountain,
            'X' => Terrain.cliff,
            '~' => Terrain.mud,
            'O' => Terrain.oasis,
            'C' => Terrain.city,
            _ => Terrain.plains,
          }
      ]
  ];

  City camp(String id, Pos c, Side s) => City(
        id: id,
        cells: [c, Pos(c.c + 1, c.r), Pos(c.c - 1, c.r), Pos(c.c, c.r + 1), Pos(c.c, c.r - 1)],
        citadel: c,
        gates: [Pos(c.c + 1, c.r), Pos(c.c - 1, c.r)],
        capitalOf: s,
      );

  final hq = camp('arish', const Pos(12, 1), Side.player);
  final qc = camp('qcamp', const Pos(21, 19), Side.ai);
  return GameMap(
    cols: badrCols,
    rows: badrRows,
    terrain: t,
    cities: [hq, qc],
    playerCapital: hq,
    enemyCapital: qc,
    messageCity: qc,
    zoneRadius: 8,
    roadCells: {for (final (c, r) in _badrRoads) Pos(c, r)},
    // deployment areas: the Muslims in the northern valley, Quraysh in front of their camp
    playerZone: {
      for (var r = 1; r <= 9; r++)
        for (var c = 8; c <= 19; c++) Pos(c, r)
    },
    enemyZone: {
      for (var r = 12; r <= 18; r++)
        for (var c = 9; c <= 19; c++) Pos(c, r)
    },
    backgroundBytes: badrMapBytes,
  );
}

const _n = ''; // narrator

final StoryChapter badrChapter = StoryChapter(
  id: 'badr',
  number: 1,
  titleFr: 'La bataille de Badr',
  titleEn: 'The Battle of Badr',
  dateFr: '17 Ramadan, an 2 de l\'Hégire (mars 624)',
  dateEn: '17 Ramadan, year 2 AH (March 624)',
  roundLimit: 25,
  rewardGold: 200,
  rewardCard: 'abudujana',
  keyWell: badrKeyWell,
  leaderId: 'abujahl',
  winReasonFr: 'Abu Jahl est tombé : l\'armée de Quraysh prend la fuite. C\'est le Jour du Discernement.',
  winReasonEn: 'Abu Jahl has fallen: the army of Quraysh flees. This is the Day of Criterion.',
  buildMap: buildBadrMap,
  playerDeck: const DeckDef(
    'story_badr',
    [
      'shieldwall', 'shieldwall', 'fortify', 'waterskins', 'waterskins', 'rally', 'rally',
      'march', 'recon', 'drums', 'arrows', 'arrows', 'charge', 'ambush',
    ],
    ['hamza', 'ali', 'abubakr', 'umar', 'zubayr', 'miqdad', 'musab', 'bilal', 'saad', 'abudujana'],
  ),
  aiDeck: const DeckDef(
    'story_badr_ai',
    [
      'arrows', 'arrows', 'charge', 'drums', 'rally', 'march', 'recon',
      'shieldwall', 'shieldwall', 'cache', 'sabotage', 'waterskins',
    ],
    ['abujahl', 'utba', 'shayba', 'walid', 'umayya', 'spearmen', 'spearmen', 'spearmen', 'archer', 'archer', 'rider', 'rider'],
  ),
  objectives: const [
    ObjectiveDef('well', 'Prendre le puits central de Badr', 'Take the central well of Badr'),
    ObjectiveDef('leader', 'Vaincre Abu Jahl, chef des Quraysh', 'Defeat Abu Jahl, leader of Quraysh'),
    ObjectiveDef('hq', 'Protéger la hutte de commandement (al-\'Arish)', 'Protect the command hut (al-\'Arish)'),
  ],
  introLines: const [
    StoryLine(_n,
        'Ramadan de l\'an 2 de l\'Hégire. Les musulmans de Médine sortent pour intercepter la grande caravane de Quraysh d\'Abu Sufyan, qui revient de Syrie.',
        'Ramadan of the year 2 AH. The Muslims of Madinah set out to intercept the great Quraysh caravan of Abu Sufyan, returning from Syria.'),
    StoryLine(_n,
        'Prévenu, Abu Sufyan dévie par la côte et appelle La Mecque à l\'aide. Une armée d\'environ mille hommes, menée par Abu Jahl, marche vers Badr. Les musulmans ne sont qu\'environ 313, avec très peu de chevaux.',
        'Warned, Abu Sufyan swerves along the coast and calls Mecca for help. An army of about a thousand men, led by Abu Jahl, marches on Badr. The Muslims are only about 313, with very few horses.'),
    StoryLine(_n,
        'Le Messager d\'Allah ﷺ consulte ses compagnons. Abu Bakr et Umar parlent avec fermeté. Puis al-Miqdad prend la parole.',
        'The Messenger of Allah ﷺ consults his companions. Abu Bakr and Umar speak firmly. Then al-Miqdad speaks.'),
    StoryLine('miqdad',
        'Nous ne dirons pas comme le peuple de Moïse : « Va, toi et ton Seigneur, et combattez, nous restons ici. » Nous combattrons à ta droite, à ta gauche, devant toi et derrière toi.',
        'We will not say as the people of Moses said: "Go, you and your Lord, and fight; we stay here." We will fight on your right, on your left, before you and behind you.'),
    StoryLine('saadmuadh',
        'Les Ansar sont avec toi. Même si tu nous menais jusqu\'à la mer, nous t\'y suivrions : aucun de nous ne restera en arrière.',
        'The Ansar are with you. Even if you led us into the sea, we would follow: not one of us will stay behind.'),
    StoryLine('hubab',
        'Cet endroit a-t-il été choisi par révélation, ou est-ce une décision de guerre ? … Alors allons au puits le plus proche de l\'ennemi, comblons les autres et construisons un bassin : nous aurons de l\'eau, eux non.',
        'Was this place chosen by revelation, or is it a decision of war? … Then let us go to the well nearest the enemy, stop up the others and build a basin: we will have water, and they will not.'),
    StoryLine(_n,
        'Le conseil est suivi. Dans la nuit, Allah fait tomber une pluie : le sol des musulmans se raffermit, celui des Quraysh devient boueux (Coran 8:11). Le Prophète ﷺ passe la nuit en prière.',
        'The advice is followed. During the night, Allah sends rain: the ground of the Muslims firms up, that of Quraysh turns to mud (Quran 8:11). The Prophet ﷺ spends the night in prayer.'),
    StoryLine(_n,
        'Objectifs : prenez le puits central, brisez l\'armée des Quraysh en abattant Abu Jahl, et protégez la hutte de commandement.',
        'Objectives: take the central well, break the army of Quraysh by defeating Abu Jahl, and protect the command hut.',
        hint: true),
    StoryLine(_n,
        'Placez vos 10 héros dans la zone bleue, puis lancez la bataille. Le sol boueux (marron) coûte 2 de mouvement : il ralentit les Quraysh.',
        'Place your 10 heroes in the blue zone, then start the battle. Muddy ground (brown) costs 2 movement: it slows Quraysh down.',
        hint: true),
  ],
  beats: const [
    StoryBeat('b_start', 'start', [
      StoryLine(_n,
          'Au matin du 17 Ramadan, les deux armées se font face. Les musulmans se rangent en lignes serrées.',
          'On the morning of 17 Ramadan, the two armies face each other. The Muslims form tight lines.'),
      StoryLine(_n,
          'Tenir un puits donne +1 énergie par tour. Des héros de même classe côte à côte avancent plus loin en troupe.',
          'Holding a well gives +1 energy per turn. Heroes of the same class side by side move farther as a troop.',
          hint: true),
    ]),
    StoryBeat('b_contact', 'contact', [
      StoryLine('abujahl',
          'Par Allah, nous ne repartirons pas avant d\'être arrivés à Badr : nous y resterons trois jours, nous égorgerons des chameaux, nous festoierons, et les Arabes entendront parler de nous.',
          'By Allah, we will not turn back until we reach Badr: we will stay there three days, slaughter camels, feast, and the Arabs will hear of us.'),
      StoryLine(_n,
          'Le brouillard de guerre cache l\'ennemi hors de votre vue. Utilisez les hauteurs et gardez vos archers derrière les lignes.',
          'The fog of war hides the enemy beyond your sight. Use high ground and keep your archers behind the lines.',
          hint: true),
    ]),
    StoryBeat('b_well', 'well', [
      StoryLine('hubab',
          'Le puits est à nous ! Les Quraysh devront se passer d\'eau.',
          'The well is ours! Quraysh will have to do without water.'),
      StoryLine(_n,
          'Vous tenez un puits : +1 énergie à chaque tour tant que l\'une de vos unités y reste.',
          'You hold a well: +1 energy each turn while one of your units stays on it.',
          hint: true),
    ]),
    StoryBeat('b_duel', 'round:2', [
      StoryLine(_n,
          'Selon la coutume arabe, trois nobles de Quraysh sortent des rangs pour défier les musulmans en combat singulier : Utba, son frère Shayba et son fils al-Walid.',
          'According to Arab custom, three nobles of Quraysh step out to challenge the Muslims to single combat: Utba, his brother Shayba and his son al-Walid.'),
      StoryLine('utba',
          'Qu\'on nous envoie nos égaux parmi les nobles de Quraysh !',
          'Send forth our equals from among the nobles of Quraysh!'),
      StoryLine(_n,
          'Hamza, Ali et Ubayda ibn al-Harith relèvent le défi. Hamza et Ali sont vos meilleurs combattants : affrontez les champions ennemis.',
          'Hamza, Ali and Ubayda ibn al-Harith take up the challenge. Hamza and Ali are your best fighters: face the enemy champions.',
          hint: true),
    ]),
    StoryBeat('b_shayba', 'kill:shayba', [
      StoryLine(_n, 'Shayba ibn Rabi\'a est tombé.', 'Shayba ibn Rabi\'a has fallen.'),
    ]),
    StoryBeat('b_walid', 'kill:walid', [
      StoryLine(_n, 'Al-Walid ibn Utba est tombé.', 'Al-Walid ibn Utba has fallen.'),
    ]),
    StoryBeat('b_utba', 'kill:utba', [
      StoryLine(_n,
          'Utba ibn Rabi\'a est tombé. Les trois champions de Quraysh ne sont plus : le moral mecquois vacille.',
          'Utba ibn Rabi\'a has fallen. The three champions of Quraysh are no more: Meccan morale wavers.'),
    ]),
    StoryBeat('b_morale', 'round:3', [
      StoryLine(_n,
          'Le Prophète ﷺ lève les mains en invocation. Allah a promis son soutien aux croyants (Coran 8:9) : les musulmans retrouvent courage.',
          'The Prophet ﷺ raises his hands in supplication. Allah promised support to the believers (Quran 8:9): the Muslims regain courage.'),
      StoryLine(_n,
          'Toutes vos unités récupèrent 2 PV.',
          'All your units recover 2 HP.',
          hint: true),
    ], healPlayer: 2),
    StoryBeat('b_wave', 'round:4', [
      StoryLine(_n,
          'Des renforts de Quraysh arrivent au camp, en nombre : l\'armée mecquoise est plus de trois fois plus nombreuse.',
          'Quraysh reinforcements reach the camp in numbers: the Meccan army is more than three times larger.'),
    ], spawnEnemy: ['spearmen', 'spearmen']),
    StoryBeat('b_umayya', 'kill:umayya', [
      StoryLine(_n,
          'Umayya ibn Khalaf, qui avait persécuté Bilal à La Mecque, tombe sur le champ de bataille.',
          'Umayya ibn Khalaf, who had persecuted Bilal in Mecca, falls on the battlefield.'),
    ]),
    StoryBeat('b_abujahl', 'kill:abujahl', [
      StoryLine(_n,
          'Deux jeunes Ansar, Mu\'adh ibn Amr et Mu\'awwidh ibn Afra, s\'étaient juré de l\'atteindre : Abu Jahl, le chef des Quraysh, est abattu et Abdullah ibn Mas\'ud l\'achève.',
          'Two young Ansar, Mu\'adh ibn Amr and Mu\'awwidh ibn Afra, had sworn to reach him: Abu Jahl, leader of Quraysh, is struck down and Abdullah ibn Mas\'ud finishes him.'),
    ]),
    StoryBeat('b_win', 'win', [
      StoryLine(_n,
          'Les Quraysh prennent la fuite. Environ soixante-dix des leurs sont tués et soixante-dix faits prisonniers. Quatorze musulmans tombent en martyrs.',
          'Quraysh flees. About seventy of them are killed and seventy taken prisoner. Fourteen Muslims fall as martyrs.'),
      StoryLine(_n,
          'Le Coran nommera ce jour Yawm al-Furqan, le Jour du Discernement (8:41). La petite communauté de Médine vient de changer le cours de l\'histoire.',
          'The Quran calls this day Yawm al-Furqan, the Day of Criterion (8:41). The small community of Madinah has just changed the course of history.'),
    ]),
    StoryBeat('b_lose', 'lose', [
      StoryLine(_n,
          'Ce n\'est pas ainsi que l\'histoire s\'est déroulée : à Badr, les musulmans l\'ont emporté. Réessayez avec une autre stratégie.',
          'This is not how history unfolded: at Badr, the Muslims won. Try again with another strategy.'),
    ]),
  ],
);

/// Expanded retelling of Badr. The original scenario above remains untouched
/// and replayable; this is a separate, longer scenario with additional phases.
final StoryChapter badrV2Chapter = StoryChapter(
  id: 'badr_v2',
  number: 2,
  titleFr: 'Badr — Le Jour du Discernement (Version II)',
  titleEn: 'Badr — The Day of Criterion (Version II)',
  dateFr: '17 Ramadan, an 2 de l\'Hégire · scénario étendu',
  dateEn: '17 Ramadan, year 2 AH · expanded scenario',
  roundLimit: 35,
  rewardGold: 250,
  keyWell: badrKeyWell,
  leaderId: 'abujahl',
  winReasonFr: 'Abu Jahl est tombé. L\'armée mecquoise perd son chef et se disloque : la bataille de Badr est remportée.',
  winReasonEn: 'Abu Jahl has fallen. The Meccan army loses its leader and breaks: the Battle of Badr is won.',
  buildMap: buildBadrMap,
  playerDeck: const DeckDef(
    'story_badr_v2',
    ['shieldwall', 'shieldwall', 'fortify', 'waterskins', 'waterskins', 'rally', 'rally',
      'march', 'recon', 'drums', 'arrows', 'arrows', 'charge', 'ambush'],
    ['hamza', 'ali', 'abubakr', 'umar', 'zubayr', 'miqdad', 'musab', 'bilal', 'saad', 'abuubayda'],
  ),
  aiDeck: const DeckDef(
    'story_badr_v2_ai',
    ['arrows', 'arrows', 'charge', 'drums', 'rally', 'march', 'recon', 'shieldwall', 'cache', 'sabotage', 'waterskins'],
    ['abujahl', 'utba', 'shayba', 'walid', 'umayya', 'spearmen', 'spearmen', 'spearmen', 'spearmen', 'archer', 'archer', 'rider'],
  ),
  objectives: const [
    ObjectiveDef('well', 'Prendre le puits et le tenir pendant deux tours sans le laisser être contesté', 'Capture the well and hold it for two uncontested turns'),
    ObjectiveDef('night', 'Tenir jusqu\'à la nuit et aux conditions favorables', 'Hold until night and the favorable conditions'),
    ObjectiveDef('champions', 'Repousser les trois champions de Quraysh', 'Defeat the three Quraysh champions'),
    ObjectiveDef('reinforcements', 'Résister aux réserves de l\'armée mecquoise', 'Withstand the Quraysh army reserves'),
    ObjectiveDef('leader', 'Vaincre Abu Jahl', 'Defeat Abu Jahl'),
  ],
  introLines: const [
    StoryLine(_n, 'La bataille de Badr se déroule le 17 Ramadan de l\'an 2 de l\'Hégire, près des puits de Badr. Ce scénario étendu reprend les grandes étapes rapportées dans les sources de la Sira et les récits historiques, tout en signalant les simplifications propres au jeu.',
      'The Battle of Badr took place on 17 Ramadan in the second year after the Hijra, near the wells of Badr. This expanded scenario follows major episodes reported in Sira and historical accounts while acknowledging the simplifications required by the game.'),
    StoryLine(_n, 'À l\'origine, l\'expédition musulmane visait la caravane de Quraysh conduite par Abu Sufyan, qui revenait du commerce en Syrie. Il ne s\'agissait pas au départ d\'une armée partie livrer une bataille rangée.',
      'The Muslim expedition initially set out in connection with the Quraysh caravan led by Abu Sufyan, returning from trade in Syria. It was not originally a force setting out for a pitched battle.'),
    StoryLine(_n, 'Abu Sufyan, averti du danger, modifia l\'itinéraire de la caravane et fit prévenir La Mecque. Une armée mecquoise se mit alors en marche. La caravane échappa à l\'interception, mais Abu Jahl choisit de poursuivre vers Badr.',
      'Warned of the danger, Abu Sufyan changed the caravan\'s route and sent word to Mecca. A Meccan force then marched out. The caravan escaped interception, but Abu Jahl chose to continue toward Badr.'),
    StoryLine(_n, 'Les récits traditionnels évaluent souvent les musulmans à environ 313 et les Quraysh à près de mille. Ces nombres sont des estimations transmises par les sources, et non un recensement moderne.',
      'Traditional accounts commonly estimate the Muslims at about 313 and Quraysh at close to a thousand. These are figures transmitted by the sources, not a modern census.'),
    StoryLine(_n, 'Vous allez revivre la préparation, le choix du terrain, la nuit précédant l\'affrontement, les défis des champions, les combats et leurs conséquences. Le plateau et les effectifs sont condensés pour rester jouables.',
      'You will experience the preparations, the choice of ground, the night before the clash, the champions\' challenges, the fighting and its aftermath. The board and troop numbers are condensed to remain playable.'),
    StoryLine(_n, 'Les paroles attribuées aux personnages sont des reconstitutions narratives inspirées des récits, pas des enregistrements mot à mot. Les scènes non établies avec certitude ne sont pas présentées comme des faits certains.',
      'Words attributed to historical figures are narrative reconstructions inspired by the accounts, not verbatim recordings. Details that are not firmly established are not presented as certain facts.'),
  ],
  beats: const [
    StoryBeat('b2_start', 'start', [
      StoryLine(_n, 'La marche vers Badr commence. L\'objectif initial lié à la caravane a changé : les deux forces se dirigent maintenant vers un affrontement près des puits.',
        'The march toward Badr begins. The initial objective connected to the caravan has changed: both forces are now moving toward a confrontation near the wells.'),
      StoryLine(_n, 'Déployez vos unités avec soin. Les combattants robustes doivent protéger les unités fragiles et les archers doivent conserver une ligne de tir dégagée.',
        'Deploy carefully. Durable fighters should protect fragile units, while archers should keep clear lines of fire.', hint: true),
    ]),
    StoryBeat('b2_council', 'round:1', [
      StoryLine(_n, 'À l\'approche de Badr, le Prophète ﷺ consulte ses compagnons sur la situation et sur la confrontation qui se dessine.',
        'As Badr approaches, the Prophet ﷺ consults his companions about the situation and the confrontation taking shape.'),
      StoryLine('miqdad', 'Nous resterons à tes côtés et ne te laisserons pas seul face à l\'épreuve.',
        'We will stand with you and will not leave you alone in this trial.'),
      StoryLine('saadmuadh', 'Les Ansar ont pris leur engagement. Nous sommes avec toi.',
        'The Ansar have made their pledge. We stand with you.'),
      StoryLine(_n, 'Le conseil et l\'engagement des compagnons donnent le ton de la campagne : coordination, discipline et confiance mutuelle.',
        'The consultation and the companions\' commitment set the tone for the campaign: coordination, discipline and mutual trust.'),
    ]),
    StoryBeat('b2_well_plan', 'round:2', [
      StoryLine('hubab', 'Si ce lieu n\'est pas imposé par une révélation, examinons la position. Le puits le plus proche de l\'ennemi et la maîtrise de l\'eau peuvent compter dans la stratégie.',
        'If this position is not divinely prescribed, let us examine the ground. The well nearest the enemy and control of water may matter strategically.'),
      StoryLine(_n, 'Les récits rapportent le conseil d\'al-Hubab ibn al-Mundhir concernant le choix d\'une position près de l\'eau. Dans le jeu, occuper le puits central matérialise cet enjeu.',
        'Accounts report al-Hubab ibn al-Mundhir\'s advice concerning a position near the water. In the game, holding the central well represents this strategic concern.'),
      StoryLine(_n, 'Prenez le puits avec une unité capable de tenir la position. Évitez d\'y envoyer seul un héros déjà affaibli.',
        'Capture the well with a unit able to hold the position. Avoid sending a weakened hero there alone.', hint: true),
    ]),
    StoryBeat('b2_recon', 'round:3', [
      StoryLine(_n, 'Les récits décrivent aussi une reconnaissance des environs. Deux hommes chargés d\'approvisionner l\'armée mecquoise sont interrogés et donnent des indications sur la présence et l\'importance de l\'armée de Quraysh.',
        'Accounts also describe reconnaissance of the area. Two men supplying the Meccan army are questioned and provide information about the presence and size of Quraysh\'s force.'),
      StoryLine(_n, 'Les estimations sont déduites notamment du nombre de chameaux abattus chaque jour. Les sources anciennes ne donnent pas toutes les mêmes chiffres : le jeu retient des ordres de grandeur.',
        'Estimates are inferred in part from the number of camels slaughtered each day. Early sources do not all give the same figures: the game uses broad approximations.'),
    ]),
    StoryBeat('b2_well_held', 'b2_well_held', [
      StoryLine('hubab', 'Le puits est défendu et votre position tient. Ne dispersez pas les forces qui le protègent : Quraysh cherchera à reprendre cet avantage.',
        'The well is defended and your position holds. Do not scatter the forces protecting it: Quraysh will try to regain this advantage.'),
      StoryLine(_n, 'Le puits est maintenant sécurisé durablement. Vous devez encore tenir face aux champions et aux réserves ennemies.',
        'The well is now secured for the long term. You must still withstand the enemy champions and reserves.', hint: true),
    ]),
    StoryBeat('b2_rain', 'round:3', [
      StoryLine(_n, 'La nuit précédant le combat, les récits évoquent une pluie qui raffermit le terrain du côté musulman et rend certaines zones plus difficiles à traverser pour les Quraysh. Le Coran évoque cette pluie en 8:11.',
        'Accounts describe rain on the night before the battle, firming the ground on the Muslim side and making some areas harder for Quraysh to cross. The Quran refers to this rain in 8:11.'),
      StoryLine(_n, 'Le calme et le repos sont également évoqués dans le récit coranique. Le terrain boueux ralentit maintenant les mouvements ennemis.',
        'Calm and rest are also mentioned in the Quranic account. Muddy ground now slows enemy movement.'),
      StoryLine(_n, 'Objectif accompli : tenez votre position et préparez la ligne de bataille. Le puits devra être défendu pendant deux tours complets.',
        'Objective complete: hold your position and prepare the battle line. The well must be defended for two full turns.', hint: true),
    ]),
    StoryBeat('b2_dawn', 'round:4', [
      StoryLine(_n, 'À l\'aube, les deux armées se mettent en ordre. La maîtrise du terrain, la cohésion des rangs et la protection des combattants vulnérables seront déterminantes.',
        'At dawn, both forces form their lines. Control of the ground, cohesion and protection of vulnerable fighters will be decisive.'),
      StoryLine(_n, 'Gardez vos archers en retrait et utilisez les collines pour améliorer leur portée. Les unités de mêlée doivent empêcher les cavaliers d\'atteindre l\'arrière-garde.',
        'Keep archers behind the line and use the hills to improve their range. Melee units should prevent cavalry from reaching the rear.', hint: true),
    ]),
    StoryBeat('b2_champions', 'round:5', [
      StoryLine(_n, 'Les récits de Badr rapportent le défi lancé par des combattants notables de Quraysh. Utba, Shayba et al-Walid sortent des rangs.',
        'Accounts of Badr report a challenge from notable Quraysh fighters. Utba, Shayba and al-Walid step forward.'),
      StoryLine('utba', 'Que ceux qui viennent nous affronter se présentent !',
        'Let those who will face us come forward!'),
      StoryLine(_n, 'Hamza, Ali et Ubayda ibn al-Harith sont associés à cet épisode dans les récits. Dans cette version, vos héros doivent neutraliser les trois champions.',
        'Hamza, Ali and Ubayda ibn al-Harith are associated with this episode in the accounts. In this version, your heroes must defeat the three champions.'),
    ]),
    StoryBeat('b2_general', 'round:6', [
      StoryLine(_n, 'Après les combats singuliers, l\'affrontement devient général. Les récits décrivent les musulmans tenant leurs rangs face aux attaques de Quraysh avant la charge décisive.',
        'After the single combats, the fighting becomes general. Accounts describe the Muslims holding their lines against Quraysh attacks before the decisive advance.'),
      StoryLine(_n, 'Ne laissez pas vos unités isolées. Une ligne de front cohérente permet aux combattants défensifs de protéger les archers et les unités de soutien.',
        'Do not leave units isolated. A coherent front lets defensive fighters protect archers and support units.', hint: true),
    ]),
    StoryBeat('b2_turning_point', 'round:9', [
      StoryLine(_n, 'Les récits traditionnels évoquent l\'ordre d\'avancer et la rupture progressive des rangs mecquois. Le Coran revient sur l\'issue de Badr dans la sourate al-Anfal.',
        'Traditional accounts describe the order to advance and the gradual breaking of the Meccan ranks. The Quran reflects on Badr in Surat al-Anfal.'),
      StoryLine(_n, 'Le champ de bataille est désormais désorganisé. Concentrez vos attaques sur les menaces prioritaires et gardez une protection autour de vos héros blessés.',
        'The battlefield is now disordered. Focus attacks on priority threats and keep protection around wounded heroes.', hint: true),
    ]),
    StoryBeat('b2_wave_one', 'round:7', [
      StoryLine(_n, 'L\'affrontement s\'étend au-delà des premiers duels. Les lignes se rapprochent et les combats deviennent plus difficiles à contrôler.',
        'The fighting spreads beyond the initial duels. The lines close and the battle becomes harder to control.'),
      StoryLine(_n, 'Dans le jeu, des unités de réserve de l\'armée déjà présente entrent dans la mêlée pour représenter ses effectifs supérieurs. Ce renfort est une abstraction ludique, pas l\'affirmation qu\'une nouvelle armée est arrivée historiquement.',
        'In the game, reserve units from the army already on the field enter the fighting to represent its greater numbers. This is a gameplay abstraction, not a claim that a new army historically arrived.', hint: true),
    ], spawnEnemy: ['spearmen', 'archer']),
    StoryBeat('b2_support', 'round:8', [
      StoryLine(_n, 'Le Coran évoque le soutien accordé aux croyants et l\'issue de Badr. Le jeu représente ce passage par un regain de cohésion, sans chercher à représenter visuellement les réalités invisibles.',
        'The Quran refers to support given to the believers and the outcome at Badr. The game represents this through renewed cohesion, without attempting to depict unseen realities.'),
      StoryLine(_n, 'Vos unités récupèrent une partie de leur endurance. Profitez de ce moment pour stabiliser le centre.',
        'Your units recover some endurance. Use this moment to stabilize the center.', hint: true),
    ], healPlayer: 1),
    StoryBeat('b2_wave_two', 'round:10', [
      StoryLine(_n, 'Une seconde partie des réserves de l\'armée mecquoise rejoint la ligne active. Le scénario répartit les forces déjà présentes en plusieurs vagues pour donner un rythme tactique à la bataille.',
        'A second part of the Meccan army reserves joins the active line. The scenario releases forces already present in several waves to create a tactical rhythm.'),
      StoryLine(_n, 'Protégez vos unités de soutien. Une formation dispersée devient vulnérable aux attaques successives.',
        'Protect your support units. A scattered formation becomes vulnerable to successive attacks.', hint: true),
    ], spawnEnemy: ['spearmen', 'rider']),
    StoryBeat('b2_umayya', 'kill:umayya', [
      StoryLine(_n, 'Umayya ibn Khalaf, connu pour les persécutions infligées à Bilal à La Mecque, est tué lors de la bataille selon les récits traditionnels.',
        'Umayya ibn Khalaf, known for the persecution of Bilal in Mecca, is killed during the battle according to traditional accounts.'),
    ]),
    StoryBeat('b2_champions_done', 'kill:utba', [
      StoryLine(_n, 'Utba ibn Rabi\'a est tombé. La défaite des chefs engagés dans le défi affaiblit le moral de Quraysh.',
        'Utba ibn Rabi\'a has fallen. The defeat of the leaders who took up the challenge weakens Quraysh morale.'),
      StoryLine(_n, 'Les récits rapportent aussi qu\'Ubayda ibn al-Harith fut grièvement blessé pendant ce duel et mourut sur le chemin du retour.',
        'Accounts also report that Ubayda ibn al-Harith was gravely wounded in this duel and died on the return journey.'),
    ]),
    StoryBeat('b2_abujahl', 'kill:abujahl', [
      StoryLine(_n, 'Abu Jahl est atteint dans le combat. Les récits rapportent que deux jeunes Ansar, Mu\'adh ibn Amr ibn al-Jamuh et Mu\'awwidh ibn Afra, l\'ont attaqué, puis qu\'Abdullah ibn Mas\'ud l\'a retrouvé et achevé.',
        'Abu Jahl is struck in the fighting. Accounts report that two young Ansar, Mu\'adh ibn Amr ibn al-Jamuh and Mu\'awwidh ibn Afra, attacked him, and that Abdullah ibn Mas\'ud later found and finished him.'),
      StoryLine(_n, 'La disparition du chef mecquois marque un tournant décisif. Mais votre mission n’est achevée que si le puits est tenu, les champions vaincus et les réserves repoussées.',
        'The loss of the Meccan commander marks a decisive turning point. But your mission is complete only if the well is held, the champions are defeated and the reserves are repelled.'),
    ]),
    StoryBeat('b2_win', 'win', [
      StoryLine(_n, 'Les récits traditionnels rapportent environ soixante-dix morts et soixante-dix prisonniers du côté de Quraysh, et quatorze musulmans tombés à Badr. Les nombres sont des estimations des sources anciennes.',
        'Traditional accounts report around seventy Quraysh dead and seventy prisoners, and fourteen Muslims who fell at Badr. These numbers are estimates from early sources.'),
      StoryLine(_n, 'Après la bataille, le sort des prisonniers fait l\'objet d\'une consultation. Les récits rapportent des avis différents, notamment sur la possibilité d\'une rançon. Le Coran aborde ensuite la question des captifs en 8:67–68.',
        'After the battle, the fate of the prisoners is discussed. Accounts report differing views, including whether ransom should be accepted. The Quran later addresses captives in 8:67–68.'),
      StoryLine(_n, 'La victoire ne met donc pas fin aux responsabilités des dirigeants : elle ouvre aussi une étape politique et humaine.',
        'Victory therefore does not end the leaders\' responsibilities: it opens a further political and human chapter.'),
      StoryLine(_n, 'Le Coran désigne Badr comme le Jour du Discernement (al-Furqan, 8:41). Cette bataille devient un événement fondateur dans la mémoire de la première communauté musulmane.',
        'The Quran refers to Badr as the Day of Criterion (al-Furqan, 8:41). The battle becomes a foundational event in the memory of the early Muslim community.'),
    ]),
    StoryBeat('b2_lose', 'lose', [
      StoryLine(_n, 'Votre armée n\'a pas réussi à tenir la position. Réessayez en protégeant vos unités de soutien, en contrôlant le puits et en évitant de disperser vos héros.',
        'Your army failed to hold its position. Try again by protecting support units, controlling the well and avoiding scattering your heroes.'),
    ]),
  ],
);

final List<StoryChapter> storyChapters = [badrChapter, badrV2Chapter, uhudChapter];
