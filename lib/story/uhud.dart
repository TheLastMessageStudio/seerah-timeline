import '../models/battlefield.dart';
import '../models/cards.dart';
import '../models/game_map.dart';
import '../models/side.dart';
import '../models/story.dart';
import '../models/terrain.dart';
import 'uhud_image.dart';

/// Uhud (Shawwal, year 3 AH / March 625). The terrain grid is read from the
/// battle map drawn under the board: the big mountain in the north-west and the
/// ridge in the north-east, the Quraysh camp on the west edge, the small
/// mountain in the middle (the archers' hill, Jabal ar-Rumat) and Khalid's
/// cavalry waiting south of it.
/// Legend: . plains   h hills   M mountain (slow, no cavalry)   X cliff (blocked)
/// C camp
const int uhudCols = 36;
const int uhudRows = 20;

/// The archers' hill: the north slope of the middle mountain. The scenario
/// watches whether archers stay on it.
final Set<Pos> uhudHill = {
  const Pos(21, 10), const Pos(22, 10), const Pos(23, 10),
  const Pos(21, 11), const Pos(22, 11), const Pos(23, 11), const Pos(24, 11),
  const Pos(25, 12),
};
const Pos uhudHillTop = Pos(23, 11);
const Pos uhudRearSpawn = Pos(23, 14);

/// South slope of the middle mountain: a unit standing here has gone round
/// by the mountain and sees Khalid's camp from behind.
final Set<Pos> uhudLift = {
  for (var r = 14; r <= 15; r++)
    for (var c = 18; c <= 27; c++)
      if (_uhudGrid[r][c] == 'M' || _uhudGrid[r][c] == 'h') Pos(c, r)
};

const List<String> _uhudGrid = [
  '.........MMMXXXXXXM..Ch..MXMMMMXXXXX',
  '..........MhXXXXXXM.CCC.......hXXXXX',
  '..........MMXXXXXXX..C.........XXXXX',
  '..........hMXXMXXXX............XXXXX',
  '...........MMMXXXXX............hMMXX',
  '............hMXXXXM.............hMMX',
  '...............Mhh...............hMX',
  '..................................hM',
  '.......................h...........h',
  '..C.................................',
  '.CCC................hMhM............',
  '..C................hXMhMM...........',
  '................hMMMXXXXXM.hh.......',
  '................MXXMMMXXXh.h........',
  'h.h...............hh.MXXM.hh...h.hh.',
  '..h.h..............h.hhhh.hh..Mhhhh.',
  'hh..hh.........................hhhMM',
  'hh..hh...........................hhM',
  '...........................h...hhhMM',
  '...........................h..hhhMMM',
];

GameMap buildUhudMap() {
  final t = [
    for (var r = 0; r < uhudRows; r++)
      [
        for (var c = 0; c < uhudCols; c++)
          switch (_uhudGrid[r][c]) {
            'h' => Terrain.hills,
            'M' => Terrain.mountain,
            'X' => Terrain.cliff,
            '~' => Terrain.mud,
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

  final hq = camp('shib', const Pos(21, 1), Side.player);
  final qc = camp('qcamp', const Pos(2, 10), Side.ai);
  return GameMap(
    cols: uhudCols,
    rows: uhudRows,
    terrain: t,
    cities: [hq, qc],
    playerCapital: hq,
    enemyCapital: qc,
    messageCity: qc,
    zoneRadius: 8,
    // Armies start on scripted cells; the zones only matter for reinforcements.
    playerZone: {
      for (var r = 0; r <= 12; r++)
        for (var c = 18; c <= 27; c++) Pos(c, r),
    },
    enemyZone: {
      for (var r = 0; r <= 19; r++)
        for (var c = 0; c <= 16; c++) Pos(c, r),
    },
    backgroundBytes: uhudMapBytes,
    bgCamps: {'qcamp'},
  );
}

const _n = ''; // narrator

/// Cells around the Quraysh camp (2,10): reaching them ends the pursuit.
final Set<Pos> uhudBooty = {
  for (var c = 0; c <= 6; c++)
    for (var r = 7; r <= 13; r++)
      if (Pos(c, r).dist(const Pos(2, 10)) <= 3) Pos(c, r),
};

final StoryChapter uhudChapter = StoryChapter(
  id: 'uhud',
  number: 3,
  titleFr: 'Uhud — La colline des archers',
  titleEn: 'Uhud — The Archers’ Hill',
  dateFr: 'Shawwal, an 3 de l’Hégire (mars 625)',
  dateEn: 'Shawwal, year 3 AH (March 625)',
  roundLimit: 28,
  rewardGold: 300,
  rewardCard: 'talha',
  surviveToWin: true,
  watchCells: uhudHill,
  liftCells: uhudLift,
  keyWell: uhudHillTop,
  leaderId: '',
  winReasonFr:
      'Le soir tombe. Les Quraysh renoncent à gravir la montagne et repartent vers La Mecque. Les musulmans ont tenu, au prix de lourdes pertes : la leçon d’Uhud restera dans la mémoire de la communauté.',
  winReasonEn:
      'Evening falls. Quraysh give up climbing the mountain and head back to Mecca. The Muslims held on at a heavy cost: the lesson of Uhud will stay in the community’s memory.',
  playerStart: const [
    StoryStart('abudujana', Pos(20, 4)),
    StoryStart('ali', Pos(20, 6)),
    StoryStart('hamza', Pos(20, 8)),
    StoryStart('talha', Pos(20, 10)),
    StoryStart('nusayba', Pos(21, 5)),
    StoryStart('musab', Pos(21, 7)),
    StoryStart('zubayr', Pos(21, 9)),
    StoryStart('rufayda', Pos(22, 7)),
    StoryStart('archer', Pos(22, 11)),
    StoryStart('abdullahjubayr', Pos(23, 11)),
    StoryStart('archer', Pos(24, 11)),
    StoryStart('saad', Pos(25, 12)),
  ],
  enemyStart: const [
    StoryStart('ikrima', Pos(10, 4)),
    StoryStart('rider', Pos(10, 5)),
    StoryStart('swordsman', Pos(11, 5)),
    StoryStart('abusufyan', Pos(12, 9)),
    StoryStart('talhatalha', Pos(14, 8)),
    StoryStart('sibaa', Pos(14, 10)),
    StoryStart('wahshi', Pos(13, 11)),
    StoryStart('spearmen', Pos(14, 7)),
    StoryStart('spearmen', Pos(14, 9)),
    StoryStart('spearmen', Pos(14, 11)),
    StoryStart('spearmen', Pos(13, 9)),
    StoryStart('swordsman', Pos(13, 8)),
    StoryStart('archer', Pos(12, 8)),
    StoryStart('archer', Pos(12, 10)),
    StoryStart('archer', Pos(11, 9)),
    StoryStart('khalid', Pos(20, 18), hold: true, guarded: true),
    StoryStart('rider', Pos(21, 18), hold: true, guarded: true),
  ],
  noCaptureWin: true,
  bootyCells: uhudBooty,
  buildMap: buildUhudMap,
  playerDeck: const DeckDef(
    'story_uhud',
    [
      'shieldwall', 'shieldwall', 'fortify', 'waterskins', 'waterskins', 'rally', 'rally',
      'march', 'recon', 'drums', 'arrows', 'arrows', 'charge', 'ambush',
    ],
    ['ali', 'hamza', 'abudujana', 'zubayr', 'talha', 'saad', 'musab', 'abdullahjubayr', 'archer', 'archer', 'nusayba', 'rufayda'],
  ),
  aiDeck: const DeckDef(
    'story_uhud_ai',
    [
      'arrows', 'arrows', 'charge', 'drums', 'rally', 'march', 'recon',
      'shieldwall', 'shieldwall', 'cache', 'sabotage', 'waterskins',
    ],
    [
      'abusufyan', 'talhatalha', 'sibaa', 'wahshi', 'ikrima', 'khalid',
      'spearmen', 'spearmen', 'spearmen', 'spearmen',
      'swordsman', 'swordsman', 'archer', 'archer', 'archer', 'rider', 'rider',
    ],
  ),
  objectives: const [
    ObjectiveDef('standard', 'Abattre Talha ibn Abi Talha, porte-étendard de Quraysh', 'Defeat Talha ibn Abi Talha, standard-bearer of Quraysh'),
    ObjectiveDef('champion', 'Abattre Sibaa ibn Abd al-Uzza, le champion qui défie les musulmans', 'Defeat Sibaa ibn Abd al-Uzza, the champion challenging the Muslims'),
    ObjectiveDef('pursue', 'Poursuivre Quraysh en fuite jusqu’à son camp (butin)', 'Pursue the fleeing Quraysh to their camp (booty)'),
    ObjectiveDef('hill', 'Optionnel : garder un archer sur la colline jusqu’à la fin de la poursuite', 'Optional: keep an archer on the hill until the pursuit ends'),
    ObjectiveDef('return', 'Revenir au camp : au moins 4 unités près de la tente', 'Return to camp: at least 4 units near the tent'),
    ObjectiveDef('flank', 'Neutraliser ou repousser la charge de Khalid ibn al-Walid', 'Defeat Khalid ibn al-Walid or survive his charge'),
    ObjectiveDef('refuge', 'Tenir le camp au pied de la montagne jusqu’au tour 28', 'Hold the camp at the foot of the mountain until round 28'),
  ],
  introLines: const [
    StoryLine(_n,
        'Un an après Badr, Quraysh veut sa revanche. Les bénéfices de la caravane d’Abu Sufyan financent une armée d’environ trois mille hommes, avec quelques centaines de cavaliers et de cottes de mailles. Elle campe près d’Uhud, au nord de Médine, au mois de Shawwal de l’an 3.',
        'A year after Badr, Quraysh wants revenge. The profits of Abu Sufyan’s caravan fund an army of about three thousand men with a few hundred cavalry and mail-coats. It camps near Uhud, north of Madinah, in Shawwal of year 3.'),
    StoryLine(_n,
        'À Médine, le Prophète ﷺ consulte ses compagnons : rester dans la ville ou sortir à la rencontre de l’ennemi ? Beaucoup de jeunes, désireux de participer à un combat comme Badr, demandent à sortir. Le Prophète ﷺ revêt son armure et part avec environ mille hommes.',
        'In Madinah the Prophet ﷺ consults his companions: stay inside the city or go out to meet the enemy? Many young men, eager to take part in a fight like Badr, ask to go out. The Prophet ﷺ puts on his armour and leaves with about a thousand men.'),
    StoryLine(_n,
        'En chemin, Abdullah ibn Ubayy se retire avec environ trois cents hommes. Il reste environ sept cents musulmans face à une armée plusieurs fois supérieure. Les chiffres sont ceux rapportés par les sources traditionnelles ; ce sont des estimations.',
        'On the way, Abdullah ibn Ubayy withdraws with about three hundred men. About seven hundred Muslims remain facing an army several times larger. These are the figures reported by traditional sources; they are estimates.'),
    StoryLine(_n,
        'Le Prophète ﷺ adosse l’armée à la montagne et place une cinquantaine d’archers, sous Abdullah ibn Jubayr, sur la petite colline qui garde le flanc et l’arrière, avec cet ordre rapporté : ne pas quitter la position, que les musulmans paraissent vainqueurs ou vaincus.',
        'The Prophet ﷺ places the army with its back to the mountain and posts some fifty archers, under Abdullah ibn Jubayr, on the small hill guarding the flank and rear, with the reported order: do not leave the position, whether the Muslims seem to be winning or losing.'),
    StoryLine(_n,
        'Vos troupes sont déjà en place, comme sur la carte historique : la ligne musulmane à l’est, Quraysh en face, et vos archers sur la pente de la montagne centrale. Vous pouvez donner un ordre de marche à une unité (bouton « Marcher vers… ») : elle avancera seule, tour après tour, vers une case éloignée.',
        'Your troops are already in position, as on the historical map: the Muslim line to the east, Quraysh facing it, and your archers on the slope of the central mountain. You can give a unit a march order (the “March to…” button): it will advance on its own, round after round, toward a distant cell.',
        hint: true),
    StoryLine(_n,
        'Les paroles prêtées aux personnages sont des reconstitutions inspirées des récits, pas des citations mot à mot. Les effectifs sont condensés pour rester jouables, et certains épisodes sont regroupés par tour. La bataille dure ici 28 tours.',
        'Words attributed to figures are reconstructions inspired by the accounts, not verbatim quotations. Numbers are condensed to stay playable and some episodes are grouped by round. The battle lasts 28 rounds here.'),
  ],
  beats: const [
    StoryBeat('u_start', 'start', [
      StoryLine(_n,
          'Les deux armées se font face dans la plaine d’Uhud. Les femmes de Quraysh, autour de Hind bint Utba, chantent et frappent les tambours pour exciter leurs hommes.',
          'The two armies face each other on the plain of Uhud. The women of Quraysh, around Hind bint Utba, chant and beat drums to rouse their men.'),
      StoryLine(_n,
          'Avant le combat, le Prophète ﷺ présente une épée en demandant qui la prendra pour en faire son droit. Abu Dujana l’accepte et noue son turban rouge, signe qu’il va combattre jusqu’au bout.',
          'Before the fighting the Prophet ﷺ holds out a sword and asks who will take it and give it its due. Abu Dujana accepts it and ties on his red turban, a sign that he will fight to the end.'),
      StoryLine(_n,
          'Vos archers, sur la montagne au centre, couvrent le flanc. Au sud de cette montagne, la cavalerie de Khalid ibn al-Walid attend et reste à l’abri : on ne peut pas l’attaquer de face. Le centre doit tenir : laissez Quraysh venir à vous.',
          'Your archers on the mountain in the middle cover the flank. South of that mountain the cavalry of Khalid ibn al-Walid waits under cover: it cannot be attacked head-on. The centre must hold: let Quraysh come to you.',
          hint: true),
    ]),
    StoryBeat('u_contact', 'contact', [
      StoryLine(_n,
          'Les premiers cavaliers et fantassins de Quraysh entrent dans votre champ de vision. Le porte-étendard Talha ibn Abi Talha avance devant les rangs et lance un défi.',
          'The first cavalry and infantry of Quraysh come into view. The standard-bearer Talha ibn Abi Talha steps in front of the ranks and issues a challenge.'),
      StoryLine('talhatalha',
          'Y a-t-il parmi vous quelqu’un pour m’affronter ?',
          'Is there anyone among you who will face me?'),
      StoryLine(_n,
          'Les récits rapportent qu’il fut abattu au combat singulier, l’étendard de Quraysh tombant avec lui. Vos héros peuvent relever ce défi : visez-le dès qu’il est à portée.',
          'Accounts report that he fell in single combat, the Quraysh standard falling with him. Your heroes can answer the challenge: strike him as soon as he is in range.',
          hint: true),
    ]),
    StoryBeat('u_standard', 'kill:talhatalha', [
      StoryLine(_n,
          'Talha ibn Abi Talha est tombé. Plusieurs porte-étendards de Quraysh se relaient ensuite pour saisir la bannière et tombent l’un après l’autre. Le moral de l’armée mecquoise vacille.',
          'Talha ibn Abi Talha has fallen. Several Quraysh standard-bearers then take turns to pick up the banner and fall one after another. The morale of the Meccan army wavers.'),
      StoryLine(_n,
          'Votre armée reprend confiance : les ennemis perdent de leur force.',
          'Your army takes heart: the enemy loses some of its strength.', hint: true),
    ], hurtEnemy: 1),
    StoryBeat('u_hamza', 'round:4', [
      StoryLine(_n,
          'Au cœur de la mêlée, Hamza, le « lion d’Allah », fait des ravages dans les rangs de Quraysh. Abu Dujana, l’épée du Prophète ﷺ à la main, perce les lignes ennemies.',
          'In the thick of the fight Hamza, the “lion of Allah”, tears through the Quraysh ranks. Abu Dujana, with the Prophet’s ﷺ sword in his hand, cuts through the enemy lines.'),
      StoryLine(_n,
          'Parmi les Mecquois, Wahshi, un esclave abyssin habile au javelot, guette Hamza depuis l’abri d’un rocher. On lui a promis sa liberté s’il le tue. Protégez Hamza : ne l’isolez pas.',
          'Among the Meccans, Wahshi, an Abyssinian slave skilled with the javelin, watches Hamza from behind a rock. He has been promised his freedom if he kills him. Protect Hamza: do not isolate him.',
          hint: true),
    ]),
    StoryBeat('u_sibaa', 'kill:sibaa', [
      StoryLine(_n,
          'Sibaa ibn Abd al-Uzza, qui défiait les musulmans, est abattu par Hamza. Les musulmans gagnent du terrain.',
          'Sibaa ibn Abd al-Uzza, who was challenging the Muslims, is cut down by Hamza. The Muslims gain ground.'),
    ]),
    StoryBeat('u_hamza_fall', 'kill:hamza', [
      StoryLine(_n,
          'Hamza ibn Abd al-Muttalib tombe, atteint par le javelot de Wahshi. Selon les récits, le Prophète ﷺ fut profondément affligé de la perte de son oncle.',
          'Hamza ibn Abd al-Muttalib falls, struck by Wahshi’s javelin. According to the accounts the Prophet ﷺ was deeply grieved by the loss of his uncle.'),
    ]),
    StoryBeat('u_break', 'round:6', [
      StoryLine(_n,
          'Sous la poussée musulmane, les lignes de Quraysh se rompent. Les récits décrivent les Mecquois qui fuient jusqu’à leur camp ; les femmes qui les encourageaient reculent.',
          'Under the Muslim push the Quraysh lines break. Accounts describe the Meccans fleeing back toward their camp; the women who had been urging them on fall back.'),
      StoryLine(_n,
          'C’est le moment de la victoire apparente : Quraysh fuit vers son camp, abandonnant armes et bagages sur le terrain.',
          'This is the moment of apparent victory: Quraysh flees toward its camp, abandoning weapons and baggage on the field.'),
      StoryLine(_n,
          'Objectif : poursuivez les fuyards jusqu’au camp mecquois, à l’ouest. Mais gardez un archer sur la colline : l’ordre était de ne pas la quitter. Votre camp, lui, devra être regagné ensuite.',
          'Objective: pursue the fugitives to the Meccan camp in the west. But keep an archer on the hill: the order was not to leave it. Your own camp will have to be regained afterwards.',
          hint: true),
    ], hurtEnemy: 2, healPlayer: 1, rout: true),
    StoryBeat('u_dispute', 'round:7', [
      StoryLine('abdullahjubayr',
          'Le Messager de Dieu ﷺ nous a ordonné de ne pas quitter cette position. Nous resterons ici.',
          'The Messenger of God ﷺ ordered us not to leave this position. We will stay here.'),
      StoryLine(_n,
          'Les récits rapportent que la majorité des archers, voyant la victoire, estiment que l’ordre est devenu sans objet et descendent pour rejoindre le butin ; Abdullah ibn Jubayr et un petit groupe refusent de bouger.',
          'Accounts report that most of the archers, seeing victory, consider the order to have lost its purpose and go down to join the spoils; Abdullah ibn Jubayr and a small group refuse to move.'),
      StoryLine(_n,
          'Dans ce scénario, c’est à vous de choisir. Quand la poursuite se termine (vous atteignez le camp ennemi, ou au tour 11), Khalid ibn al-Walid sort de sa cachette : colline vide, il frappe de plein fouet ; colline gardée, il arrive affaibli. Vous pouvez aussi l’attaquer d’abord par la montagne.',
          'In this scenario the choice is yours. When the pursuit ends (you reach the enemy camp, or round 11), Khalid ibn al-Walid leaves cover: with the hill empty he hits hard; with the hill held he arrives weakened. You can also strike him first through the mountain.',
          hint: true),
    ]),
    StoryBeat('u_booty', 'booty', [
      StoryLine(_n,
          'Vos hommes atteignent le camp de Quraysh : bagages, armes et étendards abandonnés. Les récits décrivent des musulmans qui se dispersent pour ramasser le butin.',
          'Your men reach the Quraysh camp: abandoned baggage, weapons and banners. Accounts describe Muslims scattering to gather the spoils.'),
      StoryLine(_n,
          'Mais au sud, Khalid ibn al-Walid a vu le mouvement. Retournez au camp, vite !',
          'But to the south Khalid ibn al-Walid has seen the movement. Go back to camp, quickly!',
          hint: true),
    ]),
    StoryBeat('u_booty_late', 'booty_late', [
      StoryLine(_n,
          'La poursuite s’essouffle : à force d’hésiter, vos troupes ont laissé Quraysh se reprendre. Khalid ibn al-Walid saisit l’occasion et sort de l’abri de la montagne.',
          'The pursuit runs out of breath: by hesitating, your troops let Quraysh recover. Khalid ibn al-Walid seizes the chance and leaves the shelter of the mountain.'),
    ]),
    StoryBeat('u_archers_left', 'archers_left', [
      StoryLine(_n,
          'La colline est vide. Khalid lance ses cavaliers : ils contournent la montagne par l’est et remontent vers l’arrière des musulmans.',
          'The hill is empty. Khalid sends his horsemen round the mountain by the east and up toward the Muslim rear.'),
      StoryLine(_n,
          'Abdullah ibn Jubayr et les quelques archers restés à leur poste sont submergés. Objectif : regagnez le camp et fermez vos lignes autour de la tente !',
          'Abdullah ibn Jubayr and the few archers who stayed at their post are overwhelmed. Objective: regain camp and close your lines around the tent!',
          hint: true),
    ]),
    StoryBeat('u_archers_held', 'archers_held', [
      StoryLine(_n,
          'Contrairement à l’Histoire, vos archers tiennent la colline. Khalid charge tout de même, mais sous leurs flèches : sa cavalerie arrive affaiblie.',
          'Unlike history, your archers hold the hill. Khalid charges anyway, but under their arrows: his cavalry arrives weakened.'),
      StoryLine(_n,
          'Revenez au camp pour achever de repousser la charge.',
          'Return to camp to finish driving back the charge.', hint: true),
    ]),
    StoryBeat('u_regroup', 'regroup', [
      StoryLine(_n,
          'Vos unités se regroupent autour de la tente : la ligne est refermée. Tenez bon, la cavalerie ne peut pas atteindre les pentes.',
          'Your units regroup around the tent: the line is closed. Hold fast; the cavalry cannot reach the slopes.'),
    ], healPlayer: 1),
    StoryBeat('u_lift', 'guard_lifted', [
      StoryLine(_n,
          'Vos hommes ont franchi la montagne : depuis la pente sud, ils dominent le camp de Khalid ibn al-Walid par l’arrière. La cavalerie mecquoise n’est plus à l’abri.',
          'Your men have crossed the mountain: from the south slope they overlook the camp of Khalid ibn al-Walid from behind. The Meccan cavalry is no longer sheltered.'),
      StoryLine(_n,
          'Vous pouvez maintenant l’attaquer. Si vous l’abattez avant qu’il charge, la menace sur l’arrière disparaît. Mais attention : le moment venu, il chargera quand même.',
          'You can now attack it. If you defeat him before he charges, the threat to the rear disappears. But beware: when the time comes, he will charge anyway.',
          hint: true),
    ]),
    StoryBeat('u_khalid_down', 'kill:khalid', [
      StoryLine(_n,
          'Khalid ibn al-Walid est tombé avant d’avoir pu charger : la manœuvre qui a décidé de la bataille n’aura pas lieu. C’est une variante : dans l’Histoire, il fit demi-tour et frappa l’arrière des musulmans.',
          'Khalid ibn al-Walid has fallen before he could charge: the manoeuvre that decided the battle will not happen. This is a variant: in history he turned about and struck the Muslim rear.'),
    ], healPlayer: 1),
    StoryBeat('u_cry', 'p2:3', [
      StoryLine(_n,
          'La confusion gagne le champ de bataille. Mus’ab ibn Umayr, qui portait l’étendard musulman, est attaqué ; Ibn Qami’a, croyant avoir tué le Prophète ﷺ, crie que Muhammad est mort. La rumeur se répand.',
          'Confusion spreads across the field. Mus’ab ibn Umayr, who carried the Muslim standard, is attacked; Ibn Qami’a, believing he has killed the Prophet ﷺ, cries that Muhammad is dead. The rumour spreads.'),
      StoryLine(_n,
          'Certains musulmans perdent courage et reculent ; d’autres refusent de survivre à ce qu’ils croient être sa mort et se jettent dans la mêlée. Le Prophète ﷺ est blessé : son visage est atteint et une dent est brisée, selon les récits.',
          'Some Muslims lose heart and fall back; others refuse to outlive what they believe to be his death and throw themselves into the fight. The Prophet ﷺ is wounded: his face is struck and a tooth broken, according to the accounts.'),
      StoryLine(_n,
          'Ne reculez pas en désordre. Ralliez-vous autour du camp : plus vous serez groupés, plus vos héros pourront se protéger mutuellement.',
          'Do not fall back in disorder. Rally round the camp: the more tightly you are grouped, the better your heroes can protect each other.',
          hint: true),
    ]),
    StoryBeat('u_musab', 'kill:musab', [
      StoryLine(_n,
          'Mus’ab ibn Umayr tombe en tenant l’étendard. Il ressemblait au Prophète ﷺ, ce qui explique en partie la rumeur de sa mort. Un autre compagnon prend la bannière.',
          'Mus’ab ibn Umayr falls holding the standard. He resembled the Prophet ﷺ, which partly explains the rumour of his death. Another companion takes up the banner.'),
    ]),
    StoryBeat('u_ubayy', 'p2:4', [
      StoryLine(_n,
          'Ubayy ibn Khalaf, qui avait juré à La Mecque de tuer le Prophète ﷺ, s’élance vers lui. Les compagnons veulent lui barrer la route, mais le Prophète ﷺ les laisse passer.',
          'Ubayy ibn Khalaf, who had sworn in Mecca to kill the Prophet ﷺ, rushes toward him. The companions try to block him, but the Prophet ﷺ lets him through.'),
    ], spawnEnemy: ['ubayy']),
    StoryBeat('u_ubayy_kill', 'kill:ubayy', [
      StoryLine(_n,
          'Selon les récits, Ubayy ibn Khalaf est blessé légèrement au cou d’une lance par le Prophète ﷺ lui-même ; il meurt peu après sur le chemin du retour vers La Mecque.',
          'According to the accounts Ubayy ibn Khalaf is lightly wounded at the neck by a spear from the Prophet ﷺ himself; he dies soon after on the road back to Mecca.'),
    ]),
    StoryBeat('u_defenders', 'p2:6', [
      StoryLine(_n,
          'Autour du Prophète ﷺ, quelques compagnons forment un rempart : Talha ibn Ubaydullah, Abu Dujana, Sa’d ibn Abi Waqqas, Nusayba bint Ka’b. Talha reçoit tant de coups que sa main reste paralysée, disent les récits.',
          'Around the Prophet ﷺ a few companions form a wall: Talha ibn Ubaydullah, Abu Dujana, Sa’d ibn Abi Waqqas, Nusayba bint Ka’b. Talha takes so many blows that his hand remains paralysed, the accounts say.'),
      StoryLine(_n,
          'Sa’d tire inlassablement des flèches que le Prophète ﷺ lui tend. Nusayba combat à ses côtés, malgré ses blessures.',
          'Sa’d shoots arrow after arrow that the Prophet ﷺ passes to him. Nusayba fights at their side despite her wounds.'),
      StoryLine(_n,
          'Vos unités reprennent un peu de force en se serrant autour du camp.',
          'Your units regain some strength as they close ranks around the camp.', hint: true),
    ], healPlayer: 1),
    StoryBeat('u_kab', 'p2:7', [
      StoryLine('kab',
          'Musulmans, réjouissez-vous ! Le Messager de Dieu ﷺ est vivant !',
          'Muslims, rejoice! The Messenger of God ﷺ is alive!'),
      StoryLine(_n,
          'Ka’b ibn Malik reconnaît le Prophète ﷺ sous son casque et appelle les musulmans. Les compagnons se rassemblent vers la montagne, où la cavalerie ne peut pas les suivre.',
          'Ka’b ibn Malik recognises the Prophet ﷺ under his helmet and calls the Muslims. The companions gather toward the mountain, where the cavalry cannot follow.'),
      StoryLine(_n,
          'Les montagnes et les collines vous protègent : les cavaliers ne peuvent pas gravir les pentes. Reculez vers elles et combattez depuis les hauteurs.',
          'The mountain and hills protect you: horsemen cannot climb the slopes. Fall back toward them and fight from the heights.',
          hint: true),
    ], healPlayer: 1),
    StoryBeat('u_flank_done', 'flank_done', [
      StoryLine(_n,
          'La charge de la cavalerie s’épuise : les cavaliers ne parviennent plus à atteindre les musulmans regroupés sur les pentes.',
          'The cavalry charge runs out of steam: the horsemen can no longer reach the Muslims regrouped on the slopes.'),
    ]),
    StoryBeat('u_climb', 'p2:9', [
      StoryLine(_n,
          'Un groupe de Quraysh tente de gravir la montagne. Omar ibn al-Khattab et un groupe de muhajirun les repoussent à coups de flèches et de pierres.',
          'A group of Quraysh tries to climb the mountain. Umar ibn al-Khattab and a group of the Muhajirun drive them back with arrows and stones.'),
    ], spawnEnemy: ['spearmen', 'swordsman']),
    StoryBeat('u_sufyan', 'p2:12', [
      StoryLine('abusufyan',
          'Muhammad est-il parmi vous ? Abu Bakr est-il parmi vous ? Omar est-il parmi vous ?',
          'Is Muhammad among you? Is Abu Bakr among you? Is Umar among you?'),
      StoryLine(_n,
          'Le Prophète ﷺ ordonne de ne pas répondre. Abu Sufyan, croyant qu’ils sont morts, se réjouit. Omar ne peut se retenir et répond que Dieu a gardé ceux qu’Abu Sufyan croyait morts.',
          'The Prophet ﷺ tells them not to answer. Abu Sufyan, thinking they are dead, rejoices. Umar cannot restrain himself and answers that God has kept those whom Abu Sufyan thought dead.'),
      StoryLine(_n,
          'Abu Sufyan annonce un jour pour un jour : rendez-vous à Badr l’an prochain. Quraysh commence à se retirer. Tenez encore quelques tours.',
          'Abu Sufyan announces a day for a day: a meeting at Badr next year. Quraysh begins to withdraw. Hold on a few more rounds.',
          hint: true),
    ], hurtEnemy: 1),
    StoryBeat('u_win', 'win', [
      StoryLine(_n,
          'Les récits traditionnels rapportent environ soixante-dix musulmans martyrs à Uhud, dont Hamza, Mus’ab ibn Umayr et Abdullah ibn Jubayr, et un nombre bien moindre de morts du côté de Quraysh. Ce sont des estimations.',
          'Traditional accounts report about seventy Muslim martyrs at Uhud, including Hamza, Mus’ab ibn Umayr and Abdullah ibn Jubayr, and far fewer dead on the Quraysh side. These are estimates.'),
      StoryLine(_n,
          'Le Coran revient sur Uhud dans la sourate Al Imran, notamment sur l’épreuve, la leçon de l’obéissance et le pardon accordé. Le lendemain, le Prophète ﷺ part à la poursuite de Quraysh jusqu’à Hamra al-Asad, sans les rencontrer.',
          'The Quran returns to Uhud in Surah Al Imran, notably on the trial, the lesson of obedience and the forgiveness granted. The next day the Prophet ﷺ sets out after Quraysh as far as Hamra al-Asad, without meeting them.'),
      StoryLine(_n,
          'Uhud n’est pas la victoire éclatante de Badr, mais ce n’est pas non plus une défaite totale : la communauté tient, et en tire une leçon durable sur la discipline et l’unité.',
          'Uhud is not the clear victory of Badr, nor is it a complete defeat: the community holds, and draws from it a lasting lesson about discipline and unity.'),
    ]),
    StoryBeat('u_lose', 'lose', [
      StoryLine(_n,
          'Le camp est tombé ou votre armée est détruite. À Uhud, la désorganisation a failli tout coûter. Réessayez : gardez des archers sur la colline, ne dispersez pas vos héros et regroupez-vous autour du camp.',
          'The camp has fallen or your army is destroyed. At Uhud, disorder nearly cost everything. Try again: keep archers on the hill, do not scatter your heroes, and rally around the camp.'),
    ]),
  ],
);
