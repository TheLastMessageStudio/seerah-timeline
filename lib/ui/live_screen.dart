import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../live/live_game.dart';
import '../models/battlefield.dart';
import '../models/cards.dart';
import '../models/side.dart';
import '../models/units.dart';
import '../profile.dart';
import '../story/tower.dart';
import '../strings.dart';
import 'board_view.dart';
import 'icons.dart';
import 'logo.dart';
import 'theme.dart';

String _t(String fr, String en) => currentLanguage == 'fr' ? fr : en;

/// Sariyya: the real-time mode. Give orders to groups, they walk and fight alone.
/// Used for a normal match (best of [rounds]) or for a floor of a Sariyya tower.
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key, this.deck, this.level = 6, this.rounds = 3, this.towerId, this.towerFloor});
  final DeckDef? deck;
  final int level; // AI difficulty of a normal match
  final int rounds; // 1 or 3 (best of)
  final String? towerId; // set for a tower floor
  final int? towerFloor;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with SingleTickerProviderStateMixin {
  late LiveGame game;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final Set<LiveUnit> selected = {};
  bool paused = false;
  double speed = 1;
  LiveCard? selCard; // card chosen in the hand, waiting for a spot on the map
  bool escortArm = false; // next tap on an ally chooses the unit to escort
  LiveFormation formation = LiveFormation.free;
  bool rewarded = false;
  bool roundCounted = false;
  int gold = 0, xp = 0;
  String? wonCard;
  int pWins = 0, aWins = 0, roundNo = 1;
  int _floor = 0;
  (double, double)? marker;
  double markerAge = 0;

  // camera + box selection
  final ScrollController _scroll = ScrollController();
  double _cell = 20, _viewH = 400, _boardH = 400;
  Offset? dragStart, dragNow; // in cells

  bool get _tower => widget.towerId != null;
  int get _rounds => _tower ? Tower.liveRounds(_floor) : widget.rounds;
  int get _needed => _rounds ~/ 2 + 1;
  bool get matchOver => pWins >= _needed || aWins >= _needed;

  @override
  void initState() {
    super.initState();
    _floor = widget.towerFloor ?? 0;
    _newGame();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _newGame() {
    final mine = widget.deck ?? Profile.playableDecks.first;
    final foe = decks.firstWhere((d) => d.id != mine.id, orElse: () => decks.last);
    if (_tower) {
      final def = Tower.liveTower(widget.towerId!);
      game = LiveGame(
        playerArmy: mine.army(),
        enemyArmy: Tower.liveArmy(def.id, _floor),
        seed: roundNo * 7 + _floor,
        level: Tower.liveLevel(_floor),
        rules: def.rules,
      );
    } else {
      game = LiveGame(playerArmy: mine.army(), enemyArmy: foe.army(), seed: roundNo * 7 + 1, level: widget.level);
    }
    selected.clear();
    selCard = null;
    escortArm = false;
    paused = false;
    roundCounted = false;
    marker = null;
    dragStart = null;
    dragNow = null;
  }

  void _newMatch() {
    pWins = 0;
    aWins = 0;
    roundNo = 1;
    rewarded = false;
    gold = 0;
    xp = 0;
    wonCard = null;
    _newGame();
  }

  void _nextRound() {
    roundNo++;
    _newGame();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = elapsed;
    if (game.over && !roundCounted) {
      roundCounted = true;
      if (game.winner == Side.player) {
        pWins++;
      } else {
        aWins++;
      }
      if (matchOver && !rewarded) _reward();
      if (mounted) setState(() {});
    }
    if (paused || game.over) return;
    game.tick(dt * speed);
    selected.removeWhere((u) => !u.alive);
    if (marker != null) {
      markerAge += dt;
      if (markerAge > 1.0) marker = null;
    }
    if (mounted) setState(() {});
  }

  void _reward() {
    rewarded = true;
    final won = pWins >= _needed;
    if (_tower) {
      final id = widget.towerId!;
      if (won) {
        gold = Tower.gold(_floor);
        xp = Tower.xp(_floor);
        if (_floor > (Profile.towerLive[id] ?? 0)) Profile.towerLive[id] = _floor;
        final card = Tower.rewardCard(_floor);
        if (card != null) {
          Profile.addCard(card);
          wonCard = card;
        }
      } else {
        gold = 10 + _floor * 4;
        xp = 10 + _floor * 3;
      }
    } else {
      gold = won ? 60 + widget.level * 6 : 20;
      xp = won ? 80 + widget.level * 4 : 30;
    }
    Profile.addGold(gold);
    Profile.addXp(xp);
    if (mounted) setState(() {});
  }

  // --------------------------------------------------------- input

  LiveUnit? _unitAt(double x, double y, Side side) {
    LiveUnit? best;
    var bd = 0.75;
    for (final u in game.aliveOf(side)) {
      final d = sqrt(pow(u.x - x, 2) + pow(u.y - y, 2)).toDouble();
      if (d < bd) {
        bd = d;
        best = u;
      }
    }
    return best;
  }

  void _select(Iterable<LiveUnit> units) {
    selected
      ..clear()
      ..addAll(units);
  }

  void _tap(double x, double y) {
    if (game.over) return;
    final card = selCard;
    if (card != null) {
      if (!game.canDeployAt(Side.player, x, y)) {
        setState(() => selCard = null);
        return;
      }
      final u = game.play(Side.player, card, x, y);
      setState(() {
        selCard = null;
        if (u != null) _select([u]);
      });
      return;
    }
    if (escortArm) {
      final leader = _unitAt(x, y, Side.player);
      setState(() {
        if (leader != null && selected.isNotEmpty) game.orderEscort(selected, leader);
        escortArm = false;
      });
      return;
    }
    // tapping a troop selects it alone; several units are picked by drawing a box
    final mine = _unitAt(x, y, Side.player);
    if (mine != null) {
      setState(() => _select([mine]));
      return;
    }
    if (selected.isEmpty) return;
    final enemy = _unitAt(x, y, Side.ai);
    setState(() {
      if (enemy != null) {
        game.orderAttack(selected, enemy);
      } else {
        game.orderMove(selected, x, y, formation: formation);
        marker = (x, y);
        markerAge = 0;
      }
    });
  }

  void _dragEnd() {
    final a = dragStart, b = dragNow;
    dragStart = null;
    dragNow = null;
    if (a != null && b != null) {
      final r = Rect.fromPoints(a, b);
      if (r.width >= 0.3 || r.height >= 0.3) {
        final inside = game.aliveOf(Side.player).where((u) => r.contains(Offset(u.x, u.y))).toList();
        if (inside.isNotEmpty) _select(inside);
      }
    }
    setState(() {});
  }

  void _selectWhere(bool Function(LiveUnit) test) {
    setState(() => _select(game.aliveOf(Side.player).where(test)));
  }

  // camera ----------------------------------------------------------------

  (double, double) _visibleRows() {
    final off = _scroll.hasClients ? _scroll.offset : 0.0;
    final vh = min(_viewH, _boardH);
    final bottom = _boardH - off;
    return ((bottom - vh) / _cell, bottom / _cell);
  }

  void _centerOn(double yCell) {
    if (!_scroll.hasClients) return;
    final o = _boardH - _viewH / 2 - yCell * _cell;
    _scroll.jumpTo(o.clamp(0.0, _scroll.position.maxScrollExtent).toDouble());
    setState(() {});
  }

  // ---------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1620),
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Expanded(child: LayoutBuilder(builder: (context, c) {
            final map = game.map;
            final cell = min(c.maxWidth / map.cols, 40.0);
            final w = cell * map.cols, h = cell * map.rows;
            _cell = cell;
            _viewH = c.maxHeight;
            _boardH = h;
            final board = SizedBox(
              width: w,
              height: h,
              child: Stack(children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tap(d.localPosition.dx / cell, d.localPosition.dy / cell),
                  onPanStart: (d) => setState(() {
                    dragStart = Offset(d.localPosition.dx / cell, d.localPosition.dy / cell);
                    dragNow = dragStart;
                  }),
                  onPanUpdate: (d) => setState(() => dragNow = Offset(d.localPosition.dx / cell, d.localPosition.dy / cell)),
                  onPanEnd: (_) => _dragEnd(),
                  onPanCancel: () => setState(() {
                    dragStart = null;
                    dragNow = null;
                  }),
                  child: CustomPaint(size: Size(w, h), painter: TerrainPainter(map)),
                ),
                IgnorePointer(child: CustomPaint(size: Size(w, h), painter: _UnderPainter(game, selected, cell, marker, markerAge, selCard != null))),
                for (final u in game.units)
                  Positioned(
                    left: u.x * cell - cell * 0.5,
                    top: u.y * cell - cell * 0.5,
                    width: cell,
                    height: cell,
                    child: IgnorePointer(child: UnitToken(unit: u.unit, size: cell, selected: selected.contains(u), dim: false)),
                  ),
                IgnorePointer(child: CustomPaint(size: Size(w, h), painter: _OverPainter(game, cell, dragStart, dragNow))),
              ]),
            );
            final vis = _visibleRows();
            final miniW = 54.0;
            final miniH = miniW * map.rows / map.cols;
            return Stack(children: [
              // reverse: the view starts at the bottom, on your own base.
              // Dragging draws a selection box, so the camera moves with the
              // mini-map (or the mouse wheel).
              Listener(
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent && _scroll.hasClients) {
                    _scroll.jumpTo((_scroll.offset - e.scrollDelta.dy).clamp(0.0, _scroll.position.maxScrollExtent).toDouble());
                    setState(() {});
                  }
                },
                child: SingleChildScrollView(
                  controller: _scroll,
                  reverse: true,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(width: c.maxWidth, child: Center(child: board)),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: miniW,
                  height: miniH,
                  decoration: BoxDecoration(border: Border.all(color: Pal.gold, width: 1.5), borderRadius: BorderRadius.circular(4)),
                  child: GestureDetector(
                    onTapDown: (d) => _centerOn(d.localPosition.dy / miniH * map.rows),
                    onPanUpdate: (d) => _centerOn(d.localPosition.dy / miniH * map.rows),
                    child: CustomPaint(painter: _MiniPainter(game, vis.$1, vis.$2)),
                  ),
                ),
              ),
              if (game.preparing && !game.over)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: Pal.gold)),
                        child: Text(
                          _t('PRÉPARATION  ${(LiveTuning.prepSeconds - game.time).ceil()}s — pose des cartes, donne des ordres',
                              'PREPARATION  ${(LiveTuning.prepSeconds - game.time).ceil()}s — place cards, give orders'),
                          style: const TextStyle(color: Pal.gold, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ),
              if (game.over) _endOverlay(),
            ]);
          })),
          _bottomBar(),
        ]),
      ),
    );
  }

  Widget _bar(String label, double v, double max, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (v / max).clamp(0.0, 1.0).toDouble(),
            minHeight: 9,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }

  Widget _topBar() {
    final left = max(0, (LiveTuning.prepSeconds + LiveTuning.battleSeconds - game.time)).toInt();
    final g = game;
    final title = _tower ? '${_t('Étage', 'Floor')} $_floor' : _t('Manche', 'Round');
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 2, 8, 4),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
        const SariyyaLogo(size: 30),
        const SizedBox(width: 6),
        _bar('${_t('MA BASE', 'MY BASE')} · ${g.townsOf(Side.player)}🏘', g.playerBase.hp, g.playerBase.maxHp, Pal.move),
        const SizedBox(width: 6),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$pWins - $aWins', style: const TextStyle(color: Pal.gold, fontWeight: FontWeight.w900, fontSize: 15)),
          Text('$title ${_rounds > 1 ? '$roundNo/$_rounds' : ''} · ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 9)),
        ]),
        const SizedBox(width: 6),
        _bar('${_t('ENNEMI', 'ENEMY')} · ${g.townsOf(Side.ai)}🏘', g.enemyBase.hp, g.enemyBase.maxHp, Pal.attack),
        const SizedBox(width: 2),
        IconButton(
          onPressed: () => setState(() => paused = !paused),
          icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white),
        ),
        GestureDetector(
          onTap: () => setState(() => speed = speed == 1 ? 2 : (speed == 2 ? 0.5 : 1)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: Pal.gold), borderRadius: BorderRadius.circular(8)),
            child: Text('x${speed == 0.5 ? '0.5' : speed.toInt()}', style: const TextStyle(color: Pal.gold, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }

  /// Square-ish button used in the order row.
  Widget _chip(String label, IconData icon, VoidCallback onTap, {Color color = const Color(0xFF2E4A66), bool active = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? Pal.gold : color,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: active ? Pal.ink : Colors.white, size: 18),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: active ? Pal.ink : Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  /// Small pill of the selection bar.
  Widget _pill(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: const Color(0xFF22384F),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Pal.gold, size: 15),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _cardTile(LiveCard c) {
    final h = game.handOf(Side.player);
    final alive = c.unit != null && c.unit!.alive;
    final waiting = !alive && game.time < c.readyAt;
    final affordable = h.energy >= c.cost;
    final ok = game.canPlay(Side.player, c);
    final sel = selCard == c;
    final status = alive ? _t('en jeu', 'in play') : (waiting ? '${(c.readyAt - game.time).ceil()}s' : '');
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: () {
            if (!ok) return;
            setState(() => selCard = sel ? null : c);
          },
          child: Opacity(
            opacity: ok ? 1 : 0.45,
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E4A66), Color(0xFF16263A)]),
                border: Border.all(color: sel ? Pal.gold : (c.type.isHero ? const Color(0xFFE8C45A) : Colors.white24), width: sel ? 3 : 1.5),
              ),
              child: Stack(children: [
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(typeIcon(c.type), color: Colors.white, size: 24),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(status.isEmpty ? c.type.name : status,
                          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ),
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: affordable ? const Color(0xFFB65CF0) : Colors.grey, border: Border.all(color: Colors.white, width: 1.2)),
                    child: Text('${c.cost}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String get _formationLabel => switch (formation) {
        LiveFormation.free => _t('Libre', 'Free'),
        LiveFormation.line => _t('Ligne', 'Line'),
        LiveFormation.column => _t('Colonne', 'Column'),
        LiveFormation.square => _t('Carré', 'Square'),
      };

  String _hint() {
    if (selCard != null) {
      return _t('Touche ton territoire ou une ville conquise pour poser ${selCard!.type.name}.', 'Tap your territory or a captured town to place ${selCard!.type.name}.');
    }
    if (escortArm) return _t('Touche l’allié (un héros par exemple) à escorter.', 'Tap the ally (a hero, say) to escort.');
    if (selected.isEmpty) {
      return _t('Touche une troupe pour la sélectionner, entoure-en plusieurs en glissant, ou choisis une catégorie.',
          'Tap a troop to select it, drag a box around several, or pick a category.');
    }
    return _t('${selected.length} unité(s) — touche la carte (déplacer en formation $_formationLabel) ou un ennemi (attaquer).',
        '${selected.length} unit(s) — tap the map (move in $_formationLabel formation) or an enemy (attack).');
  }

  Widget _bottomBar() {
    final h = game.handOf(Side.player);
    final hasSel = selected.isNotEmpty;
    final allHold = hasSel && selected.every((u) => u.hold);
    final allChase = hasSel && selected.every((u) => u.chase);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      color: const Color(0xFF0A1118),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFB65CF0), size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: h.energy / LiveTuning.maxEnergy, minHeight: 12, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(Color(0xFFB65CF0))),
              ),
              Text(h.energy.floor().toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
            ]),
          ),
        ]),
        const SizedBox(height: 3),
        Text(_hint(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 3),
        Row(children: [for (final c in h.hand) _cardTile(c)]),
        const SizedBox(height: 4),
        // selection categories
        SizedBox(
          height: 30,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _pill(_t('Aucun', 'None'), Icons.close_rounded, () => setState(selected.clear)),
            _pill(_t('Tous', 'All'), Icons.select_all_rounded, () => _selectWhere((u) => true)),
            _pill(_t('Héros', 'Heroes'), Icons.star_rounded, () => _selectWhere((u) => u.isHero)),
            _pill(_t('Mêlée', 'Melee'), Icons.shield_rounded, () => _selectWhere((u) => !u.isArcher && !u.isCavalry)),
            _pill(_t('Archers', 'Archers'), Icons.my_location_rounded, () => _selectWhere((u) => u.isArcher)),
            _pill(_t('Cavaliers', 'Cavalry'), Icons.bolt_rounded, () => _selectWhere((u) => u.isCavalry)),
            _pill(_t('À l’écran', 'On screen'), Icons.visibility_rounded, () {
              final v = _visibleRows();
              _selectWhere((u) => u.y >= v.$1 && u.y <= v.$2);
            }),
            _pill(_t('Blessés', 'Wounded'), Icons.healing_rounded, () => _selectWhere((u) => u.hp < u.maxHp * 0.6)),
            _pill(_t('Inactifs', 'Idle'), Icons.pause_circle_rounded, () => _selectWhere((u) => !u.hasDest && u.target == null && u.escortOf == null && !u.hold)),
          ]),
        ),
        const SizedBox(height: 4),
        // orders for the selected group
        Row(children: [
          _chip(_t('Tenir', 'Hold'), Icons.pan_tool_rounded, () {
            if (hasSel) setState(() => game.orderHold(selected));
          }, active: allHold),
          _chip(_t('Escorter', 'Escort'), Icons.group_rounded, () {
            if (hasSel) setState(() => escortArm = !escortArm);
          }, active: escortArm),
          _chip(allChase || !hasSel ? _t('Poursuite', 'Pursue') : _t('Sans poursuite', 'No pursuit'), allChase || !hasSel ? Icons.directions_run_rounded : Icons.do_not_disturb_on_rounded, () {
            if (hasSel) setState(() => game.setChase(selected, !allChase));
          }),
          _chip(_formationLabel, Icons.view_module_rounded, () {
            setState(() {
              formation = LiveFormation.values[(formation.index + 1) % LiveFormation.values.length];
              // regroup the selection around its center right away
              if (selected.length >= 2 && formation != LiveFormation.free) {
                var cx = 0.0, cy = 0.0;
                for (final u in selected) {
                  cx += u.x;
                  cy += u.y;
                }
                game.orderMove(selected, cx / selected.length, cy / selected.length, formation: formation);
              }
            });
          }),
          _chip(_t('Charge !', 'Charge!'), Icons.flag_rounded, () {
            if (hasSel) setState(() => game.orderCharge(selected, formation: formation));
          }, color: const Color(0xFF9A2B22)),
        ]),
      ]),
    );
  }

  Widget _endOverlay() {
    final roundWon = game.winner == Side.player;
    final done = matchOver;
    final won = pWins >= _needed;
    final best = _tower ? (Profile.towerLive[widget.towerId!] ?? 0) : 0;
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Pal.parchment, borderRadius: BorderRadius.circular(14), border: Border.all(color: Pal.bronze, width: 2)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SariyyaLogo(size: 54),
            const SizedBox(height: 4),
            Text(
              done
                  ? (won ? (_tower ? _t('ÉTAGE RÉUSSI !', 'FLOOR CLEARED!') : _t('MATCH GAGNÉ !', 'MATCH WON!')) : _t('MATCH PERDU', 'MATCH LOST'))
                  : (roundWon ? _t('MANCHE GAGNÉE', 'ROUND WON') : _t('MANCHE PERDUE', 'ROUND LOST')),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: (done ? won : roundWon) ? Pal.green : Pal.enemy),
            ),
            if (_rounds > 1) Text('$pWins - $aWins', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Pal.indigo)),
            if (done) ...[
              const SizedBox(height: 6),
              Text('+$gold ${_t('or', 'gold')}  ·  +$xp XP', style: const TextStyle(fontWeight: FontWeight.w800, color: Pal.bronze)),
              if (wonCard != null)
                Text(_t('Carte de héros gagnée : ${unitById[wonCard]?.name ?? ''}', 'Hero card won: ${unitById[wonCard]?.name ?? ''}'),
                    textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Pal.green)),
              if (_tower) Text(_t('Meilleur étage : $best', 'Best floor: $best'), style: const TextStyle(color: Pal.ink)),
            ],
            const SizedBox(height: 12),
            if (!done)
              ElevatedButton(onPressed: () => setState(_nextRound), child: Text(_t('Manche suivante', 'Next round')))
            else if (_tower && won)
              ElevatedButton(
                onPressed: () => setState(() {
                  _floor++;
                  _newMatch();
                }),
                child: Text(_t('Étage suivant (${_floor + 1})', 'Next floor (${_floor + 1})')),
              )
            else if (_tower)
              ElevatedButton(
                onPressed: () => setState(() {
                  _floor = Tower.startFloor(Profile.towerLive[widget.towerId!] ?? 0);
                  _newMatch();
                }),
                child: Text(_t('Repartir de l’étage ${Tower.startFloor(Profile.towerLive[widget.towerId!] ?? 0)}', 'Restart from floor ${Tower.startFloor(Profile.towerLive[widget.towerId!] ?? 0)}')),
              )
            else
              ElevatedButton(onPressed: () => setState(_newMatch), child: Text(_t('Nouveau match', 'New match'))),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(_t('Quitter', 'Leave'))),
          ]),
        ),
      ),
    );
  }
}

Color _sideColor(Side? s) => s == Side.player ? Pal.player : (s == Side.ai ? Pal.enemy : Pal.gold);

/// Drawn under the unit tokens: territory, towns, bases, selection rings, orders.
class _UnderPainter extends CustomPainter {
  _UnderPainter(this.g, this.selected, this.cell, this.marker, this.markerAge, this.showZone);
  final bool showZone;
  final LiveGame g;
  final Set<LiveUnit> selected;
  final double cell;
  final (double, double)? marker;
  final double markerAge;

  @override
  void paint(Canvas canvas, Size size) {
    if (showZone) {
      final p = Paint()..color = Pal.gold.withAlpha(46);
      for (var r = 0; r < g.map.rows; r++) {
        for (var c = 0; c < g.map.cols; c++) {
          if (g.canDeployAt(Side.player, c + 0.5, r + 0.5)) {
            canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), p);
          }
        }
      }
    }
    for (final town in g.towns) {
      final c = Offset(town.x * cell, town.y * cell);
      final col = _sideColor(town.owner);
      canvas.drawCircle(c, cell * 1.4, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = col.withAlpha(110));
      canvas.drawCircle(c, cell * 0.7, Paint()..color = col.withAlpha(215));
      canvas.drawCircle(c, cell * 0.7, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white);
      final tp = TextPainter(text: TextSpan(text: '🏘️', style: TextStyle(fontSize: cell * 0.6)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      for (final s in Side.values) {
        final pr = town.progressOf(s);
        if (pr > 0.01 && town.owner != s) {
          canvas.drawArc(Rect.fromCircle(center: c, radius: cell * 0.95), -pi / 2, 2 * pi * pr, false,
              Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5..color = _sideColor(s));
        }
      }
    }
    for (final b in [g.playerBase, g.enemyBase]) {
      final col = _sideColor(b.side);
      final c = Offset(b.x * cell, b.y * cell);
      canvas.drawCircle(c, cell * LiveTuning.baseTowerRange, Paint()..color = col.withAlpha(22));
      canvas.drawCircle(c, cell * LiveTuning.baseTowerRange, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = col.withAlpha(110));
      canvas.drawCircle(c, cell * 0.62, Paint()..color = col);
      canvas.drawCircle(c, cell * 0.62, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = Colors.white);
      final tp = TextPainter(text: TextSpan(text: b.side == Side.player ? '🏰' : '🏯', style: TextStyle(fontSize: cell * 0.7)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
    final line = Paint()..color = Pal.gold.withAlpha(150)..strokeWidth = 1.6;
    for (final u in selected) {
      if (!u.alive) continue;
      final uc = Offset(u.x * cell, u.y * cell);
      canvas.drawCircle(uc, cell * 0.55, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = Pal.gold);
      if (u.destX != null) {
        canvas.drawLine(uc, Offset(u.destX! * cell, u.destY! * cell), line);
        canvas.drawCircle(Offset(u.destX! * cell, u.destY! * cell), cell * 0.12, Paint()..color = Pal.gold);
      }
      final t = u.target;
      if (t != null && t.alive) {
        canvas.drawLine(uc, Offset(t.x * cell, t.y * cell), Paint()..color = Pal.attack.withAlpha(180)..strokeWidth = 1.6);
      }
      final l = u.escortOf;
      if (l != null && l.alive) {
        canvas.drawLine(uc, Offset(l.x * cell, l.y * cell), Paint()..color = Colors.lightBlueAccent.withAlpha(190)..strokeWidth = 1.6);
        canvas.drawCircle(Offset(l.x * cell, l.y * cell), cell * 0.7, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.lightBlueAccent);
      }
    }
    final m = marker;
    if (m != null) {
      final k = (markerAge / 1.0).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(Offset(m.$1 * cell, m.$2 * cell), cell * (0.25 + 0.5 * k),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Pal.gold.withAlpha((255 * (1 - k)).toInt()));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// Drawn above the tokens: HP bars, stance marks, shots, damage, selection box.
class _OverPainter extends CustomPainter {
  _OverPainter(this.g, this.cell, this.dragStart, this.dragNow);
  final LiveGame g;
  final double cell;
  final Offset? dragStart, dragNow;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in g.shots) {
      final a = (1 - s.age / 0.25).clamp(0.0, 1.0).toDouble();
      canvas.drawLine(
        Offset(s.ax * cell, s.ay * cell),
        Offset(s.bx * cell, s.by * cell),
        Paint()
          ..strokeWidth = s.ranged ? 1.8 : 3
          ..color = (s.ranged ? const Color(0xFFFFE08A) : Colors.white).withAlpha((220 * a).toInt()),
      );
    }
    for (final u in g.units) {
      if (!u.alive) continue;
      final w = cell * 0.8;
      final x = u.x * cell - w / 2;
      final y = u.y * cell - cell * 0.62;
      canvas.drawRect(Rect.fromLTWH(x, y, w, 4), Paint()..color = Colors.black87);
      final f = (u.hp / u.maxHp).clamp(0.0, 1.0).toDouble();
      canvas.drawRect(Rect.fromLTWH(x, y, w * f, 4), Paint()..color = u.side == Side.player ? Pal.move : Pal.attack);
      if (u.hold) {
        // amber square = holding position
        canvas.drawRect(Rect.fromLTWH(x + w - 5, y + 6, 6, 6), Paint()..color = const Color(0xFFFFB300));
      }
      if (u.escortOf != null) {
        canvas.drawCircle(Offset(x + w - 2, y + 9), 3, Paint()..color = Colors.lightBlueAccent);
      }
    }
    for (final b in [g.playerBase, g.enemyBase]) {
      final w = cell * 1.3;
      final x = b.x * cell - w / 2;
      final y = b.y * cell - cell * 0.95;
      canvas.drawRect(Rect.fromLTWH(x, y, w, 5), Paint()..color = Colors.black87);
      canvas.drawRect(Rect.fromLTWH(x, y, w * (b.hp / b.maxHp).clamp(0.0, 1.0), 5), Paint()..color = b.side == Side.player ? Pal.move : Pal.attack);
    }
    for (final f in g.fx) {
      final tp = TextPainter(
        text: TextSpan(text: f.text, style: TextStyle(color: (f.good ? Pal.gold : Colors.white).withAlpha((255 * (1 - f.age / 0.8)).toInt()), fontSize: cell * 0.4, fontWeight: FontWeight.w900, shadows: const [Shadow(color: Colors.black, blurRadius: 2)])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.x * cell - tp.width / 2, (f.y - f.age * 0.8) * cell));
    }
    final a = dragStart, b = dragNow;
    if (a != null && b != null) {
      final r = Rect.fromPoints(a * cell, b * cell);
      canvas.drawRect(r, Paint()..color = Pal.gold.withAlpha(40));
      canvas.drawRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Pal.gold);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// Whole field in a thumbnail: tap or drag it to move the camera.
class _MiniPainter extends CustomPainter {
  _MiniPainter(this.g, this.top, this.bottom);
  final LiveGame g;
  final double top, bottom; // visible rows

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / g.map.cols;
    final ch = size.height / g.map.rows;
    for (var r = 0; r < g.map.rows; r++) {
      for (var c = 0; c < g.map.cols; c++) {
        canvas.drawRect(Rect.fromLTWH(c * cw, r * ch, cw + 0.6, ch + 0.6), Paint()..color = terrainColor(g.map.terrainAt(Pos(c, r))));
      }
    }
    for (final t in g.towns) {
      canvas.drawCircle(Offset(t.x * cw, t.y * ch), cw * 0.9, Paint()..color = _sideColor(t.owner));
    }
    for (final b in [g.playerBase, g.enemyBase]) {
      canvas.drawCircle(Offset(b.x * cw, b.y * ch), cw * 1.3, Paint()..color = _sideColor(b.side));
      canvas.drawCircle(Offset(b.x * cw, b.y * ch), cw * 1.3, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white);
    }
    for (final u in g.alive) {
      canvas.drawCircle(Offset(u.x * cw, u.y * ch), max(1.2, cw * 0.45), Paint()..color = u.side == Side.player ? const Color(0xFF1B7BFF) : const Color(0xFFE02A1A));
    }
    canvas.drawRect(
      Rect.fromLTRB(0, top * ch, size.width, bottom * ch),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
