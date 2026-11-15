import '../strings.dart';
import 'battlefield.dart';
import 'cards.dart';
import 'game_map.dart';
import 'units.dart';

/// Speakers that are not units (name only, no portrait).
const Map<String, String> storyExtraNames = {
  'hubab': 'al-Hubab ibn al-Mundhir',
  'saadmuadh': 'Sa\'d ibn Mu\'adh',
  'herald': 'Quraysh',
  'hind': 'Hind bint Utba',
  'kab': 'Ka\'b ibn Malik',
};

/// One line of narration or dialogue. [speaker] is a unit id, an extra
/// speaker id, or '' for the narrator. A [hint] is a gameplay tip.
class StoryLine {
  const StoryLine(this.speaker, this.fr, this.en, {this.hint = false});
  final String speaker;
  final String fr;
  final String en;
  final bool hint;

  String get text => currentLanguage == 'fr' ? fr : en;

  String get speakerName {
    if (hint) return tr('story_hint');
    if (speaker.isEmpty) return tr('story_narrator');
    return unitById[speaker]?.name ?? storyExtraNames[speaker] ?? speaker;
  }
}

/// Dialogue shown when [trigger] happens in battle, with optional effects.
/// Triggers: start, round:N, contact, well, kill:<unitId>, win, lose.
class StoryBeat {
  const StoryBeat(
    this.id,
    this.trigger,
    this.lines, {
    this.healPlayer = 0,
    this.spawnEnemy = const [],
    this.spawnRear = const [],
    this.hurtEnemy = 0,
    this.release = false,
    this.rout = false,
  });
  final String id;
  final String trigger;
  final List<StoryLine> lines;
  final int healPlayer; // HP given to every player unit
  final List<String> spawnEnemy; // unit ids appearing at the enemy camp
  final List<String> spawnRear; // unit ids appearing at the chapter's rear spawn cell
  final int hurtEnemy; // HP removed from every enemy unit (never below 1)
  final bool release; // enemy units waiting on hold start to act
  final bool rout; // the enemy army flees toward its own camp
}

/// A scenario-placed unit: [id] is a unit type taken from the deck's army.
/// [hold] units wait (no move, no attack) until released; [guarded] units
/// cannot be targeted until the player reaches the chapter's lift cells.
class StoryStart {
  const StoryStart(this.id, this.pos, {this.hold = false, this.guarded = false});
  final String id;
  final Pos pos;
  final bool hold;
  final bool guarded;
}

class ObjectiveDef {
  const ObjectiveDef(this.id, this.fr, this.en);
  final String id; // well | leader | hq
  final String fr;
  final String en;
  String get text => currentLanguage == 'fr' ? fr : en;
}

class StoryChapter {
  StoryChapter({
    required this.id,
    required this.number,
    required this.titleFr,
    required this.titleEn,
    required this.dateFr,
    required this.dateEn,
    required this.introLines,
    required this.beats,
    required this.objectives,
    required this.playerDeck,
    required this.aiDeck,
    required this.buildMap,
    required this.keyWell,
    required this.leaderId,
    required this.winReasonFr,
    required this.winReasonEn,
    this.roundLimit = 25,
    this.rewardGold = 200,
    this.rewardCard = '',
    this.surviveToWin = false,
    this.rearSpawn,
    this.watchCells = const {},
    this.liftCells = const {},
    this.playerStart = const [],
    this.enemyStart = const [],
    this.bootyCells = const {},
    this.noCaptureWin = false,
  });

  final String id;
  final int number;
  final String titleFr;
  final String titleEn;
  final String dateFr;
  final String dateEn;
  final List<StoryLine> introLines;
  final List<StoryBeat> beats;
  final List<ObjectiveDef> objectives;
  final DeckDef playerDeck;
  final DeckDef aiDeck;
  final GameMap Function() buildMap;
  final Pos keyWell;
  final String leaderId; // unit id of the enemy leader: defeat it to win
  final String winReasonFr;
  final String winReasonEn;
  final int roundLimit;
  final int rewardGold;
  final String rewardCard; // hero id given the first time you win
  final bool surviveToWin; // reaching the round limit with the camp held is a win
  final Pos? rearSpawn; // where scripted flank units appear
  final Set<Pos> watchCells; // cells whose occupation is tracked (Uhud hill)
  final Set<Pos> liftCells; // a player unit here ends the protection of guarded enemies
  final List<StoryStart> playerStart; // fixed starting positions (empty = deploy freely)
  final List<StoryStart> enemyStart; // fixed enemy positions (empty = automatic)
  final Set<Pos> bootyCells; // a player unit here ends the pursuit phase (Uhud enemy camp)
  final bool noCaptureWin; // holding the enemy capital does not win the chapter

  bool get fr => currentLanguage == 'fr';
  String get title => fr ? titleFr : titleEn;
  String get date => fr ? dateFr : dateEn;
  String get winReason => fr ? winReasonFr : winReasonEn;
}
