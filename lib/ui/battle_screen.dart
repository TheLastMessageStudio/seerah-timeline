import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/ai.dart';
import '../engine/game.dart';
import '../models/battlefield.dart';
import '../models/cards.dart';
import '../models/side.dart';
import '../models/story.dart';
import '../models/terrain.dart';
import '../models/units.dart';
import '../profile.dart';
import '../story/tower.dart';
import '../strings.dart';
import 'board_view.dart';
import 'card_tile.dart';
import 'icons.dart';
import 'rules_screen.dart';
import 'story_dialog.dart';
import 'theme.dart';
import '../services/sfx.dart';

/// What the player is currently doing.
enum UiMode { normal, place, card, unit }

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.deck, required this.mode, this.chapter, this.towerFloor});
  final DeckDef deck;
  final GameMode mode;
  final StoryChapter? chapter; // story mode
  final int? towerFloor; // tower mode: starting floor

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  static const double cellSize = 40;
  Size viewSize = const Size(360, 380);

  late Game game;
  final TransformationController tc = TransformationController();
  UiMode mode = UiMode.normal;
  int? selIndex; // selected card (index in hand)
  Unit? selUnit; // selected own unit
  UnitType? placeType; // unit type chosen in the deployment tray
  Unit? inspectUnit;
  Pos? inspectCell;
  bool troopMode = true;
  bool orderMode = false; // next map tap sets a march destination
  bool showDanger = false;
  String message = '';
  bool isError = false;
  bool busy = false; // enemy turn running
  int gen = 0; // changes on restart (stops a running AI loop)
  bool fitted = false;
  final List<FxItem> fx = [];
  int fxIndex = 0;
  int fxId = 0;
  int xpGain = 0;
  int goldGain = 0;
  int? newLevel;
  bool xpDone = false;
  bool _storyOpen = false;
  bool storyReward = false;
  int _floor = 0; // tower floor (0 = not the tower)
  String? towerCard; // hero card won on a boss floor
  bool get _tower => _floor > 0;

  @override
  void initState() {
    super.initState();
    _floor = widget.towerFloor ?? 0;
    _newGame();
    final ch = widget.chapter;
    if (ch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showStoryDialog(
          context,
          ch.introLines,
          header: '${tr('story_chapter', {'n': ch.number})} · ${ch.title}\n${ch.date}',
          footer: tr('story_intro_note'),
        );
      });
    }
  }

  @override
  void dispose() {
    tc.dispose();
    super.dispose();
  }

  void _newGame() {
    gen++;
    final seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final ch = widget.chapter;
    if (ch != null) {
      game = Game(
        playerDeck: ch.playerDeck,
        aiDeck: ch.aiDeck,
        mode: GameMode.story,
        seed: seed,
        gameMap: ch.buildMap(),
        chapter: ch,
      );
    } else if (_tower) {
      final cardsFrom = decks.firstWhere((d) => d.id != widget.deck.id);
      game = Game(
        playerDeck: widget.deck,
        aiDeck: Tower.deckFor(_floor, cardsFrom),
        mode: GameMode.rush,
        seed: seed,
        aiBoost: Tower.boost(_floor),
      );
    } else {
      final enemy = decks.firstWhere((d) => d.id != widget.deck.id);
      game = Game(
        playerDeck: widget.deck,
        aiDeck: enemy,
        mode: widget.mode,
        seed: seed,
      );
    }
    storyReward = false;
    towerCard = null;
    _clear();
    fx.clear();
    fxIndex = 0;
    xpGain = 0;
    goldGain = 0;
    newLevel = null;
    xpDone = false;
    busy = false;
    message = tr('msg_deploy');
    isError = false;
  }

  // ------------------------------------------------------------ helpers

  PlayerState get _me => game.players[Side.player]!;
  bool get _canAct =>
      !busy && !game.over && game.phase == Phase.battle && game.current == Side.player;

  CardDef? get _selCard {
    final i = selIndex;
    if (i == null || i < 0 || i >= _me.hand.length) return null;
    return _me.hand[i];
  }

  void _say(String m, {bool error = false}) {
    message = m;
    isError = error;
  }

  void _clear() {
    mode = UiMode.normal;
    selIndex = null;
    selUnit = null;
    placeType = null;
    inspectUnit = null;
    inspectCell = null;
    orderMode = false;
  }

  void _act(void Function() f) {
    setState(() {
      f();
      _pumpFx();
      if (game.over && !xpDone) {
        if (game.winner == Side.player) { Sfx.victory(); } else { Sfx.impact(); }
        xpDone = true;
        _award();
      }
    });
    if (game.chapter != null && game.storyQueue.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _flushStory());
    }
  }

  /// Shows the queued story dialogues one after the other.
  Future<void> _flushStory() async {
    if (_storyOpen || !mounted) return;
    _storyOpen = true;
    try {
      while (mounted && game.storyQueue.isNotEmpty) {
        final beat = game.storyQueue.removeAt(0);
        await showStoryDialog(context, beat.lines);
      }
    } finally {
      _storyOpen = false;
    }
    if (mounted) setState(() {});
  }

  void _showObjectives() {
    final ch = game.chapter;
    if (ch == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('story_objectives')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final o in ch.objectives)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(game.objectiveDone(o.id) ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 20, color: game.objectiveDone(o.id) ? Pal.green : Pal.bronze),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.text),
                          if (ch.id == 'badr_v2' && o.id == 'well')
                            Text(currentLanguage == 'fr'
                                ? '${game.badrWellHoldTurns}/2 tours de contrôle sans contestation'
                                : '${game.badrWellHoldTurns}/2 uncontested control turns',
                                style: const TextStyle(fontSize: 11, color: Pal.bronze)),
                          if (ch.id == 'badr_v2' && o.id == 'reinforcements')
                            Text(currentLanguage == 'fr'
                                ? '${game.badrReserveRemaining} soldats de réserve encore en jeu'
                                : '${game.badrReserveRemaining} reserve soldiers remaining',
                                style: const TextStyle(fontSize: 11, color: Pal.bronze)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('story_close')))],
      ),
    );
  }

  /// XP: big reward for a win, small consolation otherwise.
  void _award() {
    final kills = game.players[Side.ai]!.fallen.length;
    final won = game.winner == Side.player;
    var xp = won ? 100 + kills * 10 : 20 + kills * 5;
    if (won && game.mode == GameMode.messenger) xp += 50;
    if (game.isDraw) xp = 40;
    xpGain = xp;
    var gold = won ? 60 + kills * 8 : 15 + kills * 3;
    if (won && game.mode == GameMode.messenger) gold += 40;
    if (game.isDraw) gold = 30;
    if (_tower) {
      if (won) {
        xp = Tower.xp(_floor) + kills * 5;
        gold = Tower.gold(_floor);
        if (_floor > Profile.towerBest) Profile.towerBest = _floor;
        final card = Tower.rewardCard(_floor);
        if (card != null) {
          Profile.addCard(card);
          towerCard = card;
        }
      } else {
        xp = 10 + _floor * 3;
        gold = 10 + _floor * 4;
      }
    }
    final ch = widget.chapter;
    if (ch != null && won && !Profile.storyDone.contains(ch.id)) {
      gold += ch.rewardGold;
      storyReward = true;
      Profile.completeChapter(ch.id, ch.rewardCard);
    }
    goldGain = gold;
    Profile.addGold(gold);
    final before = Profile.level;
    Profile.addXp(xp);
    if (Profile.level > before) newLevel = Profile.level;
  }

  void _pumpFx() {
    final vis = game.visibleTo(Side.player);
    while (fxIndex < game.events.length) {
      final e = game.events[fxIndex++];
      if (!vis.contains(e.pos)) continue;
      final id = fxId++;
      final color = e.kind == 0 ? Pal.attack : (e.kind == 1 ? Pal.move : Pal.gold);
      if (e.kind == 0) { Sfx.impact(); } else { Sfx.tap(); }
      fx.add(FxItem(id, e.pos, e.text, color));
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (mounted) setState(() => fx.removeWhere((f) => f.id == id));
      });
    }
  }

  Unit? _visibleUnitAt(Pos p) {
    final u = game.unitAt(p);
    return (u != null && game.canSee(Side.player, u)) ? u : null;
  }

  void _fit() {
    final m = game.map;
    final s = min(viewSize.width / (cellSize * m.cols), viewSize.height / (cellSize * m.rows));
    tc.value = Matrix4.diagonal3Values(s, s, 1);
  }

  void _centerOn(Pos p, {double? scale}) {
    final s = scale ?? tc.value.getMaxScaleOnAxis();
    final x = (p.c + 0.5) * cellSize * s;
    final y = (p.r + 0.5) * cellSize * s;
    tc.value = Matrix4.identity()
      ..translate(viewSize.width / 2 - x, viewSize.height / 2 - y)
      ..scale(s, s, 1.0);
  }

  void _zoom(double f) {
    final m = tc.value;
    final cur = m.getMaxScaleOnAxis();
    final target = (cur * f).clamp(0.12, 3.5).toDouble();
    final k = target / cur;
    final cx = viewSize.width / 2, cy = viewSize.height / 2;
    final z = Matrix4.identity()
      ..translate(cx, cy)
      ..scale(k, k, 1.0)
      ..translate(-cx, -cy);
    tc.value = z * m;
  }

  Pos _armyCenter() {
    final mine = game.unitsOf(Side.player).toList();
    if (mine.isEmpty) return game.map.capitalOf(Side.player);
    final c = mine.fold(0, (s, u) => s + u.pos.c) ~/ mine.length;
    final r = mine.fold(0, (s, u) => s + u.pos.r) ~/ mine.length;
    return Pos(c, r);
  }

  Set<Pos> get _moveCells {
    final u = selUnit;
    if (mode != UiMode.unit || u == null || u.moved || !_canAct || orderMode) return <Pos>{};
    if (troopMode && game.troopOf(u).length > 1) return game.troopDestinations(u);
    return game.reachable(u).keys.toSet();
  }

  Set<Pos> get _attackCells {
    final u = selUnit;
    if (mode != UiMode.unit || u == null || u.attacked || !_canAct || orderMode) return <Pos>{};
    return game.attackTargets(u).map((t) => t.pos).toSet();
  }

  Set<Pos> get _placeCells => (game.phase == Phase.deploy && placeType != null)
      ? game.deployCells(Side.player)
      : <Pos>{};

  Set<Pos> get _targetCells {
    final c = _selCard;
    if (mode != UiMode.card || c == null) return <Pos>{};
    switch (c.target) {
      case TargetKind.friendlyUnit:
      case TargetKind.enemyUnit:
        return game.validUnitTargets(c).map((u) => u.pos).toSet();
      case TargetKind.ownCity:
        return game.validCellTargets(c);
      case TargetKind.anyCell:
      case TargetKind.none:
        return <Pos>{};
    }
  }

  Set<Pos> get _dangerCells => (showDanger && game.phase == Phase.battle)
      ? game.dangerZone(Side.player)
      : <Pos>{};

  // -------------------------------------------------------------- input

  void _chooseType(UnitType t) {
    _act(() {
      _clear();
      placeType = t;
      mode = UiMode.place;
      _say(tr('hint_place', {'name': t.name}));
    });
  }

  void _autoPlace() {
    _act(() {
      _clear();
      game.autoPlace(Side.player);
      _say(tr('msg_autoplaced'));
    });
  }

  void _startBattle() {
    _act(() {
      final err = game.beginBattle();
      if (err != null) {
        _say(err, error: true);
      } else {
        _clear();
        _say(tr('msg_battle'));
        _centerOn(game.map.capitalOf(Side.player), scale: 0.9);
      }
    });
  }

  void _onCard(int i) {
    if (!_canAct) return;
    _act(() {
      final c = _me.hand[i];
      if (selIndex == i && mode == UiMode.card) {
        _clear();
        _say(tr('msg_cancel'));
        return;
      }
      if (_me.energy < c.cost) {
        _say(tr('err_energy', {'cost': c.cost, 'have': _me.energy}), error: true);
        return;
      }
      _clear();
      selIndex = i;
      mode = UiMode.card;
      switch (c.target) {
        case TargetKind.friendlyUnit:
        case TargetKind.enemyUnit:
          if (game.validUnitTargets(c).isEmpty) {
            _clear();
            _say(tr('err_notarget', {'name': c.name}), error: true);
          } else {
            _say(tr('hint_target', {'name': c.name}));
          }
        case TargetKind.ownCity:
          if (game.validCellTargets(c).isEmpty) {
            _clear();
            _say(tr('err_nocity'), error: true);
          } else {
            _say(tr('hint_city', {'name': c.name}));
          }
        case TargetKind.anyCell:
          _say(tr('hint_cell', {'name': c.name}));
        case TargetKind.none:
          _say(tr('hint_notarget', {'name': c.name}));
      }
    });
  }

  void _playNoTarget() {
    final c = _selCard;
    if (c == null || !_canAct) return;
    _act(() {
      final err = game.playTactical(c);
      if (err != null) {
        _say(err, error: true);
      } else {
        _clear();
        _say('');
      }
    });
  }

  void _select(Unit u) {
    _clear();
    selUnit = u;
    mode = UiMode.unit;
    troopMode = game.troopOf(u).length > 1;
    _say(u.moved && u.attacked ? tr('state_spent') : tr('hint_unit'));
  }

  void _onMap(Pos p) {
    if (game.over) return;
    _act(() {
      if (game.phase == Phase.deploy) {
        _tapDeploy(p);
        return;
      }
      if (!_canAct) {
        inspectUnit = _visibleUnitAt(p);
        inspectCell = inspectUnit == null ? p : null;
        return;
      }
      switch (mode) {
        case UiMode.card:
          _tapCard(p);
        case UiMode.unit:
          _tapUnitMode(p);
        case UiMode.place:
        case UiMode.normal:
          final u = _visibleUnitAt(p);
          if (u != null && u.side == Side.player) {
            _select(u);
          } else {
            _clear();
            inspectUnit = u;
            inspectCell = u == null ? p : null;
            _say('');
          }
      }
    });
  }

  void _tapDeploy(Pos p) {
    final u = game.unitAt(p);
    if (u != null && u.side == Side.player) {
      game.pickUp(u);
      _clear();
      placeType = u.type;
      mode = UiMode.place;
      _say(tr('hint_place', {'name': u.type.name}));
      return;
    }
    final t = placeType;
    if (t == null) {
      inspectUnit = null;
      inspectCell = p;
      return;
    }
    final err = game.placeUnit(t, p);
    if (err != null) {
      _say(err, error: true);
    } else {
      if (!_me.roster.contains(t)) {
        placeType = null;
        mode = UiMode.normal;
      }
      _say('');
    }
  }

  void _tapCard(Pos p) {
    final c = _selCard;
    if (c == null) {
      _clear();
      return;
    }
    String? err;
    switch (c.target) {
      case TargetKind.friendlyUnit:
      case TargetKind.enemyUnit:
        final u = _visibleUnitAt(p);
        err = u == null ? tr('err_target') : game.playTactical(c, target: u);
      case TargetKind.ownCity:
      case TargetKind.anyCell:
        err = game.playTactical(c, cell: p);
      case TargetKind.none:
        _say(tr('hint_notarget', {'name': c.name}));
        return;
    }
    if (err != null) {
      _say(err, error: true);
    } else {
      _clear();
      _say('');
    }
  }

  void _tapUnitMode(Pos p) {
    final s = selUnit;
    if (s == null) {
      _clear();
      return;
    }
    if (orderMode) {
      final err = game.setDestination(s, p);
      orderMode = false;
      if (err == null) Sfx.move();
      _say(err ?? '', error: err != null);
      return;
    }
    final u = _visibleUnitAt(p);
    if (u != null && u.side == Side.player) {
      if (identical(u, s)) {
        _clear();
        _say('');
      } else {
        _select(u);
      }
      return;
    }
    String? err;
    if (u != null) {
      err = game.attack(s, u);
      if (err == null) Sfx.attack();
    } else if (troopMode && game.troopOf(s).length > 1) {
      err = game.moveTroop(s, p);
      if (err == null) Sfx.move();
    } else {
      err = game.move(s, p);
      if (err == null) Sfx.move();
    }
    _say(err ?? '', error: err != null);
  }

  Future<void> _endTurn() async {
    if (!_canAct) return;
    final myGen = gen;
    _act(() {
      _clear();
      _say('');
      game.endTurn();
      busy = !game.over;
    });
    var n = 0;
    while (busy && n < Ai.maxActions) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      while (_storyOpen && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      if (!mounted || myGen != gen) return;
      var did = false;
      _act(() => did = Ai.step(game));
      if (!did || game.over) break;
      n++;
    }
    if (!mounted || myGen != gen) return;
    _act(() {
      if (!game.over) game.endTurn();
      busy = false;
    });
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewH = min(size.height * 0.45, 420.0);
    return Scaffold(
      appBar: AppBar(
        title: Text(_tower ? tr('tower_floor', {'n': _floor}) : (widget.chapter?.title ?? tr('app_title'))),
        actions: [
          if (widget.chapter != null)
            IconButton(
              tooltip: tr('story_objectives'),
              icon: const Icon(Icons.flag),
              onPressed: _showObjectives,
            ),
          IconButton(
            tooltip: tr('ui_rules'),
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RulesScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statusBar(),
                      const SizedBox(height: 6),
                      _map(viewH),
                      _toolbar(),
                      _infoPanel(),
                      _messageArea(),
                      if (game.phase == Phase.deploy) ..._deployArea() else ..._handArea(),
                    ],
                  ),
                ),
              ),
            ),
            if (game.over) _overlay(),
          ],
        ),
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onPressed) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: IconButton(
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      );

  Widget _map(double viewH) {
    final vis = game.visibleTo(Side.player);
    return Container(
      height: viewH,
      decoration: BoxDecoration(
        border: Border.all(color: Pal.gold, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Pal.indigo,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LayoutBuilder(builder: (context, cons) {
          viewSize = Size(cons.maxWidth, cons.maxHeight);
          if (!fitted) {
            fitted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _centerOn(game.map.capitalOf(Side.player), scale: 0.9);
            });
          }
          return Stack(
            children: [
              InteractiveViewer(
                transformationController: tc,
                constrained: false,
                minScale: 0.12,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.all(120),
                child: BoardView(
                  game: game,
                  cell: cellSize,
                  visible: vis,
                  moveCells: _moveCells,
                  attackCells: _attackCells,
                  placeCells: _placeCells,
                  targetCells: _targetCells,
                  dangerCells: _dangerCells,
                  selectedUnit: selUnit,
                  fx: fx,
                  onTap: _onMap,
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: MiniMap(game: game, onTap: (p) => _centerOn(p)),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Column(
                  children: [
                    _zoomButton(Icons.add, () => _zoom(1.35)),
                    _zoomButton(Icons.remove, () => _zoom(1 / 1.35)),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.zoom_out_map, size: 16),
            label: Text(tr('ui_fit')),
            onPressed: _fit,
          ),
          ActionChip(
            avatar: const Icon(Icons.groups, size: 16),
            label: Text(tr('ui_center_army')),
            onPressed: () => _centerOn(_armyCenter(), scale: 0.9),
          ),
          ActionChip(
            avatar: const Icon(Icons.location_city, size: 16),
            label: Text(tr('ui_center_capital')),
            onPressed: () => _centerOn(game.map.capitalOf(Side.player), scale: 0.9),
          ),
          if (game.phase == Phase.battle)
            FilterChip(
              avatar: const Icon(Icons.warning_amber, size: 16),
              label: Text(tr('ui_danger')),
              selected: showDanger,
              onSelected: (v) => setState(() => showDanger = v),
            ),
          if (game.canUndo && _canAct)
            ActionChip(
              avatar: const Icon(Icons.undo, size: 16),
              label: Text(tr('ui_undo')),
              onPressed: () => _act(() {
                final err = game.undoMove();
                _say(err ?? tr('msg_undone'), error: err != null);
                if (err == null) _clear();
              }),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Pal.bronze),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(fontSize: 12.5)),
        ],
      );

  String _objectiveText() {
    final map = game.map;
    if (game.mode == GameMode.messenger) {
      Unit? m;
      for (final u in game.unitsOf(Side.player)) {
        if (u.type.id == 'messenger') m = u;
      }
      return tr('obj_messenger', {
        'dest': map.messageCity.name,
        'where': m == null ? '-' : m.pos.label,
      });
    }
    return tr('obj_conquest', {
      'enemy': map.enemyCapital.name,
      'mine': map.playerCapital.name,
      'p': game.players[Side.player]!.objectiveProgress,
      'e': game.players[Side.ai]!.objectiveProgress,
      'n': Game.captureTurns,
    });
  }

  Widget _statusBar() {
    final turnText = game.over
        ? ''
        : (game.phase == Phase.deploy
            ? tr('ui_deploy')
            : (game.current == Side.player ? tr('ui_your_turn') : tr('ui_enemy_turn')));
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Pal.parchment,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Pal.bronze),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr('ui_round', {'n': min(game.round, game.roundLimit), 'max': game.roundLimit}),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                turnText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: game.current == Side.player ? Pal.player : Pal.enemy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              _chip(Icons.bolt, tr('ui_energy_n', {'n': _me.energy})),
              _chip(Icons.style, tr('ui_deck_n', {'n': _me.drawPile.length})),
              _chip(Icons.location_city, tr('ui_cities_n', {'n': game.ownedCities(Side.player)})),
              if (game.holdsOasis(Side.player)) _chip(Icons.local_drink, tr('ui_oasis_bonus')),
              if (game.sandstorm > 0) _chip(Icons.cloud, tr('ui_sandstorm')),
            ],
          ),
          const SizedBox(height: 4),
          Text(_objectiveText(), style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _unitInfo(Unit u) {
    final t = game.map.terrainAt(u.pos);
    String state = '';
    if (u.side == Side.player && game.phase == Phase.battle) {
      if (u.moved && u.attacked) {
        state = tr('state_spent');
      } else if (u.moved) {
        state = tr('state_moved');
      } else if (u.attacked) {
        state = tr('state_attacked');
      } else {
        state = tr('state_ready');
      }
    }
    final bits = <String>[
      if (u.tempDef > 0) tr('buff_def', {'n': u.tempDef}),
      if (u.tempAtk > 0) tr('buff_atk', {'n': u.tempAtk}),
      if (u.bonusDef > 0) tr('buff_dug'),
      if (u.weak > 0) tr('debuff_weak'),
      if (u.slow > 0) tr('debuff_slow'),
      if (u.ambush) tr('buff_ambush'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(typeIcon(u.type), color: u.side == Side.player ? Pal.player : Pal.enemy),
            const SizedBox(width: 6),
            Expanded(
              child: Text(u.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
        Text(tr('info_stats', {
          'hp': u.hp,
          'max': u.maxHp,
          'mv': game.moveBudget(u),
          'atk': game.attackPower(u),
          'def': game.defenseOf(u),
          'vis': game.visionOf(u),
        })),
        Text(tr('info_attack', {'pattern': patternText(u.type)})),
        if (u.type.named)
          Text(u.type.title, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Pal.bronze)),
        Text(u.type.description, style: const TextStyle(fontSize: 12)),
        if (u.type.abilities.isNotEmpty)
          Text(u.type.abilities.join(' · '), style: const TextStyle(fontSize: 12, color: Pal.green)),
        if (bits.isNotEmpty) Text(bits.join(' · '), style: const TextStyle(fontSize: 12, color: Pal.bronze)),
        if (state.isNotEmpty) Text(state),
        if (u.dest != null) Text(tr('info_marching', {'pos': u.dest!.label}), style: const TextStyle(fontSize: 12, color: Pal.player)),
        Text(tr('info_on', {'terrain': t.label, 'desc': t.description}),
            style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _infoPanel() {
    final c = _selCard;
    final pt = placeType;
    Widget body;
    if (mode == UiMode.card && c != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(cardIcon(c), color: Pal.bronze),
            const SizedBox(width: 6),
            Expanded(
              child: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ]),
          Text(tr('card_cost', {'n': c.cost})),
          Text(c.description),
        ],
      );
    } else if (mode == UiMode.place && pt != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(typeIcon(pt), color: Pal.player),
            const SizedBox(width: 6),
            Expanded(
              child: Text(pt.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ]),
          Text(tr('info_type', {
            'hp': pt.hp,
            'mv': pt.move,
            'atk': pt.attack,
            'def': pt.defense,
            'vis': pt.vision,
          })),
          Text(tr('info_attack', {'pattern': patternText(pt)})),
          if (pt.named)
            Text(pt.title, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Pal.bronze)),
          Text(pt.description, style: const TextStyle(fontSize: 12)),
          if (pt.abilities.isNotEmpty)
            Text(pt.abilities.join(' · '), style: const TextStyle(fontSize: 12, color: Pal.green)),
        ],
      );
    } else if (selUnit != null || inspectUnit != null) {
      body = _unitInfo((selUnit ?? inspectUnit)!);
    } else if (inspectCell != null) {
      final t = game.map.terrainAt(inspectCell!);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${t.label} (${inspectCell!.label})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(t.description),
          Text(tr('terrain_stats', {
            'cost': t.moveCost,
            'def': t.defense,
            'rng': t.rangeBonus,
          }), style: const TextStyle(fontSize: 12)),
        ],
      );
    } else {
      body = Text(game.phase == Phase.deploy ? tr('deploy_hint') : tr('info_hint'));
    }

    final su = selUnit;
    final troopSize = su == null ? 0 : game.troopOf(su).length;
    final showPlay = mode == UiMode.card && c != null && c.target == TargetKind.none;
    final showCancel = mode != UiMode.normal;
    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minHeight: 86),
      decoration: BoxDecoration(
        color: Pal.parchment,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Pal.bronze),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          body,
          if (mode == UiMode.unit && su != null && troopSize > 1 && _canAct)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(tr('ui_move_troop', {'n': troopSize})),
                    selected: troopMode,
                    onSelected: (_) => setState(() => troopMode = true),
                  ),
                  ChoiceChip(
                    label: Text(tr('ui_move_alone')),
                    selected: !troopMode,
                    onSelected: (_) => setState(() => troopMode = false),
                  ),
                ],
              ),
            ),
          if (mode == UiMode.unit && su != null && su.side == Side.player && _canAct && game.phase == Phase.battle)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.flag, size: 18),
                    label: Text(tr('ui_march_to')),
                    onPressed: () => setState(() {
                      orderMode = true;
                      _say(tr('msg_march_pick'));
                    }),
                  ),
                  if (su.dest != null)
                    OutlinedButton(
                      onPressed: () => _act(() {
                        game.setDestination(su, null);
                        orderMode = false;
                        _say('');
                      }),
                      child: Text(tr('ui_march_cancel')),
                    ),
                ],
              ),
            ),
          if (showCancel || showPlay)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (showPlay)
                    ElevatedButton(
                      onPressed: _canAct ? _playNoTarget : null,
                      child: Text(tr('ui_play_card')),
                    ),
                  if (showPlay) const SizedBox(width: 8),
                  if (showCancel)
                    OutlinedButton(
                      onPressed: () => _act(() {
                        _clear();
                        _say(tr('msg_cancel'));
                      }),
                      child: Text(tr('ui_cancel')),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageArea() {
    final lines = game.log.length > 4 ? game.log.sublist(game.log.length - 4) : game.log;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E9CC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.isEmpty ? ' ' : message,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isError ? Pal.attack : Pal.green,
            ),
          ),
          for (final l in lines) Text(l, style: const TextStyle(fontSize: 12, color: Pal.ink)),
        ],
      ),
    );
  }

  List<Widget> _deployArea() {
    final roster = _me.roster;
    final counts = <UnitType, int>{};
    for (final t in roster) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return [
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Pal.parchment,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Pal.bronze),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('ui_tray', {'n': roster.length}),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (roster.isEmpty)
              Text(tr('msg_allplaced'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in counts.entries)
                    ChoiceChip(
                      avatar: Icon(typeIcon(e.key), size: 16),
                      label: Text('${e.key.name} ×${e.value}'),
                      selected: placeType?.id == e.key.id,
                      onSelected: (_) => _chooseType(e.key),
                    ),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: roster.isEmpty ? null : _autoPlace,
              child: Text(tr('ui_autoplace')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _startBattle,
              child: Text(tr('ui_start_battle')),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _handArea() {
    final hand = _me.hand;
    return [
      SizedBox(
        height: 144,
        child: hand.isEmpty
            ? Center(child: Text(tr('ui_hand_empty')))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hand.length,
                itemBuilder: (context, i) {
                  final c = hand[i];
                  return CardTile(
                    card: c,
                    selected: selIndex == i && mode == UiMode.card,
                    enabled: _canAct && _me.energy >= c.cost,
                    onTap: () => _onCard(i),
                  );
                },
              ),
      ),
      ElevatedButton.icon(
        onPressed: _canAct ? _endTurn : null,
        icon: const Icon(Icons.flag),
        label: Text(busy ? tr('ui_enemy_turn') : tr('ui_end_turn')),
      ),
    ];
  }

  Widget _overlay() {
    final w = game.winner;
    final title = w == Side.player
        ? tr('ui_victory')
        : (w == Side.ai ? tr('ui_defeat') : tr('ui_draw_result'));
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Pal.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Pal.bronze, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: w == Side.player ? Pal.green : Pal.enemy,
                ),
              ),
              const SizedBox(height: 8),
              Text(game.endReason, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(tr('xp_gain', {'n': xpGain}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Pal.bronze)),
              Text(tr('gold_gain', {'n': goldGain}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Pal.gold)),
              if (storyReward && (widget.chapter?.rewardCard ?? '').isNotEmpty)
                Text(tr('story_reward', {'card': unitById[widget.chapter!.rewardCard]?.name ?? ''}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Pal.green)),
              if (towerCard != null)
                Text(tr('tower_card', {'card': unitById[towerCard]?.name ?? ''}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Pal.green)),
              if (newLevel != null)
                Text(tr('xp_levelup', {'n': newLevel}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Pal.green)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => setState(() {
                  if (_tower && w == Side.player) {
                    _floor++;
                  } else if (_tower) {
                    _floor = Tower.startFloor(Profile.towerBest);
                  }
                  _newGame();
                  fitted = false;
                }),
                child: Text(_tower
                    ? (w == Side.player
                        ? tr('tower_next', {'n': _floor + 1})
                        : tr('tower_retry', {'n': Tower.startFloor(Profile.towerBest)}))
                    : tr('ui_restart')),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(tr('ui_menu')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
