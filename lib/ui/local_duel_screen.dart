import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_map.dart';
import '../models/battlefield.dart';
import '../models/terrain.dart';
import '../multiplayer/local_duel.dart';
import 'theme.dart';

class LocalDuelLobbyScreen extends StatefulWidget {
  const LocalDuelLobbyScreen({super.key});

  @override
  State<LocalDuelLobbyScreen> createState() => _LocalDuelLobbyScreenState();
}

class _LocalDuelLobbyScreenState extends State<LocalDuelLobbyScreen> {
  final _ip = TextEditingController();
  LocalDuelRoom? _room;
  StreamSubscription<Map<String, dynamic>>? _sub;
  String _status = 'Crée une salle ou rejoins celle de ton adversaire.';
  bool _working = false;

  @override
  void dispose() {
    _ip.dispose();
    _sub?.cancel();
    _room?.close();
    super.dispose();
  }

  Future<void> _host() async {
    setState(() { _working = true; _status = 'Création de la salle…'; });
    try {
      final room = await LocalDuelRoom.createHost();
      if (!mounted) { await room.close(); return; }
      setState(() {
        _room = room;
        _status = 'Partage ta connexion Wi-Fi ou active ton point d’accès.';
        _working = false;
      });
      _sub = room.updates.listen((state) {
        if (!mounted) return;
        setState(() {
          _status = state['connected'] == true
              ? 'Adversaire connecté. Vous pouvez lancer le duel.'
              : 'En attente du deuxième joueur…';
        });
      });
    } catch (e) {
      if (mounted) setState(() { _working = false; _status = 'Impossible de créer la salle : $e'; });
    }
  }

  Future<void> _join() async {
    final address = _ip.text.trim();
    if (address.isEmpty) { setState(() => _status = 'Entre l’adresse IP affichée chez l’hôte.'); return; }
    setState(() { _working = true; _status = 'Connexion à $address…'; });
    try {
      final room = await LocalDuelRoom.join(address);
      if (!mounted) { await room.close(); return; }
      setState(() { _room = room; _working = false; _status = 'Connecté à la salle. Prêt pour le duel.'; });
      _sub = room.updates.listen((state) {
        if (!mounted) return;
        setState(() => _status = state['connected'] == false
            ? 'Connexion interrompue.' : 'Connecté à la salle. Prêt pour le duel.');
      });
    } catch (e) {
      if (mounted) setState(() { _working = false; _status = 'Connexion impossible. Vérifie l’IP et le même réseau Wi-Fi. ($e)'; });
    }
  }

  void _enterGame() {
    final room = _room;
    if (room == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocalDuelScreen(room: room)));
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final connected = room?.state['connected'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('DUEL LOCAL · 1v1')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Pal.indigo, Color(0xFF101A29)],
        )),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.wifi_tethering, color: Pal.gold, size: 54),
                  const SizedBox(height: 10),
                  const Text('RUSH · FACE À FACE', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('Deux appareils sur le même réseau local. Pas de compte, pas de serveur externe.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.4)),
                  const SizedBox(height: 24),
                  _panel(
                    icon: Icons.wifi_tethering,
                    title: 'Créer une partie',
                    subtitle: 'Un joueur active le partage de connexion et héberge la salle.',
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      FilledButton.icon(onPressed: _working || room != null ? null : _host,
                        icon: const Icon(Icons.add_link), label: const Text('HÉBERGER UNE PARTIE')),
                      if (room?.isHost == true) ...[
                        const SizedBox(height: 14),
                        const Text('Adresse à communiquer au deuxième joueur', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        SelectableText('${room!.ipAddress}:${LocalDuelRoom.port}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Pal.gold, fontWeight: FontWeight.w900, fontSize: 22)),
                        const Text('Le joueur invité doit saisir uniquement l’adresse IP, sans le port.',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _panel(
                    icon: Icons.login,
                    title: 'Rejoindre une partie',
                    subtitle: 'Entre l’adresse IP affichée sur l’appareil de ton adversaire.',
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      TextField(controller: _ip, enabled: room == null && !_working,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Adresse IP de l’hôte', hintText: '192.168.1.10',
                          labelStyle: TextStyle(color: Colors.white70), hintStyle: TextStyle(color: Colors.white38),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Pal.gold))),),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(onPressed: _working || room != null ? null : _join,
                        icon: const Icon(Icons.link), label: const Text('REJOINDRE')),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Pal.gold.withAlpha(90))),
                    child: Row(children: [
                      Icon(connected ? Icons.check_circle : Icons.info_outline,
                        color: connected ? Colors.lightGreenAccent : Pal.gold),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_status, style: const TextStyle(color: Colors.white, height: 1.35))),
                    ])),
                  if (connected) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _enterGame, icon: const Icon(Icons.sports_martial_arts),
                      label: const Text('ENTRER DANS LE DUEL')),
                  ],
                  if (_working) const Padding(padding: EdgeInsets.only(top: 14),
                    child: Center(child: CircularProgressIndicator(color: Pal.gold))),
                  const SizedBox(height: 14),
                  const Text('Conseil : sur Android, active le point d’accès mobile sur l’hôte, puis connecte le second appareil à ce réseau avant de lancer la recherche.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4), textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel({required IconData icon, required String title, required String subtitle, required Widget child}) =>
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        color: const Color(0xFF24344B), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Pal.gold.withAlpha(130)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: Pal.gold), const SizedBox(width: 9),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17))]),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12), child,
        ]));
}

class LocalDuelScreen extends StatefulWidget {
  const LocalDuelScreen({super.key, required this.room});
  final LocalDuelRoom room;

  @override
  State<LocalDuelScreen> createState() => _LocalDuelScreenState();
}

class _LocalDuelScreenState extends State<LocalDuelScreen> {
  late Map<String, dynamic> state;
  StreamSubscription<Map<String, dynamic>>? _sub;
  String? selectedUnit;
  String? selectedDeployment = 'guard';
  final GameMap map = GameMap.rush();

  @override
  void initState() {
    super.initState();
    state = widget.room.state;
    _sub = widget.room.updates.listen((next) {
      if (!mounted) return;
      setState(() {
        state = next;
        if (selectedUnit != null && !(units.any((u) => u['id'] == selectedUnit))) selectedUnit = null;
        final availableIds = LocalDuelRoom.roster
            .where((d) => !myUnits.any((u) => u['type'] == d['id']))
            .map((d) => d['id'] as String).toList();
        if (selectedDeployment != null && !availableIds.contains(selectedDeployment)) {
          selectedDeployment = availableIds.isEmpty ? null : availableIds.first;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get units => List<Map<String, dynamic>>.from(
    ((state['units'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));
  String get side => widget.room.localSide;
  String get phase => state['phase']?.toString() ?? 'preparation';
  bool get myTurn => state['turn'] == side;
  bool get finished => (state['winner']?.toString() ?? '').isNotEmpty;
  int get remaining => state['remaining'] is int ? state['remaining'] as int : 60;
  List<Map<String, dynamic>> get myUnits => units.where((u) => u['side'] == side).toList();
  List<Map<String, dynamic>> get enemyUnits => units.where((u) => u['side'] != side).toList();

  void _tapCell(int x, int y) {
    if (finished) return;
    if (phase == 'preparation') {
      final ready = (state['ready'] as Map?)?[side] == true;
      if (!ready && selectedDeployment != null) {
        widget.room.sendAction('place', {'id': selectedDeployment, 'x': x, 'y': y});
      }
      return;
    }
    if (!myTurn) return;
    final target = _firstOrNull(units.where((u) => u['x'] == x && u['y'] == y));
    if (target != null && target['side'] == side) {
      setState(() => selectedUnit = target['id'] as String);
      return;
    }
    final selected = _firstOrNull(units.where((u) => u['id'] == selectedUnit && u['side'] == side));
    if (selected == null) return;
    if (target != null && target['side'] != side) {
      widget.room.sendAction('attack', {'id': selected['id'], 'target': target['id']});
    } else {
      widget.room.sendAction('move', {'id': selected['id'], 'x': x, 'y': y});
    }
    setState(() => selectedUnit = null);
  }

  @override
  Widget build(BuildContext context) {
    final isPrep = phase == 'preparation';
    final ready = (state['ready'] as Map?)?[side] == true;
    final deployed = myUnits.length;
    final winner = state['winner']?.toString() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF101A29),
      appBar: AppBar(title: const Text('RUSH · DUEL 1v1'), backgroundColor: Pal.indigo,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 6), child: Row(children: [
          _playerPill('JOUEUR 1', state['turn'] == 'host', Pal.player),
          const Spacer(),
          Column(children: [Text(isPrep ? 'PRÉPARATION' : (finished ? 'FIN DE PARTIE' : 'TOUR ${state['turnNumber'] ?? 1}'),
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 3), Text('${remaining}s', style: TextStyle(color: remaining <= 10 ? Colors.redAccent : Pal.gold,
              fontWeight: FontWeight.w900, fontSize: 20))]),
          const Spacer(),
          _playerPill('JOUEUR 2', state['turn'] == 'guest', Pal.enemy),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: remaining / 60, minHeight: 5,
            backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(remaining <= 10 ? Colors.redAccent : Pal.gold)))),
        Padding(padding: const EdgeInsets.fromLTRB(12, 7, 12, 7), child: Text(
          state['message']?.toString() ?? 'Prépare tes troupes', textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
            child: AspectRatio(aspectRatio: 14 / 19,
              child: Builder(builder: (boardContext) => GestureDetector(onTapUp: (details) {
                final box = boardContext.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.globalPosition);
                final cellW = box.size.width / map.cols;
                final cellH = box.size.height / map.rows;
                _tapCell((local.dx / cellW).floor(), (local.dy / cellH).floor());
              }, child: CustomPaint(painter: _RushBoardPainter(map: map, units: units,
                selectedId: selectedUnit, localSide: side), child: const SizedBox.expand())))),
          )))),
        if (isPrep) _preparationControls(ready, deployed) else _battleControls(),
        if (finished) Container(width: double.infinity, padding: const EdgeInsets.all(16), color: const Color(0xFF24344B),
          child: Column(children: [Text(winner == side ? 'VICTOIRE !' : 'DÉFAITE',
            style: TextStyle(color: winner == side ? Colors.lightGreenAccent : Colors.redAccent,
              fontSize: 24, fontWeight: FontWeight.w900)),
            Text(state['message']?.toString() ?? '', style: const TextStyle(color: Colors.white70)),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('RETOUR AU MENU'))])),
      ])),
    );
  }

  Widget _playerPill(String label, bool active, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: active ? color.withAlpha(55) : Colors.white.withAlpha(8),
      borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? color : Colors.white24, width: active ? 2 : 1)),
    child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)));

  Widget _preparationControls(bool ready, int deployed) {
    final available = LocalDuelRoom.roster.where((d) => !myUnits.any((u) => u['type'] == d['id'])).toList();
    return Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(color: Color(0xFF1B2A41), border: Border(top: BorderSide(color: Colors.white12))),
      child: Column(children: [
        Row(children: [Text('Déploiement : $deployed/4', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(), Text(ready ? 'PRÊT' : 'Place tes unités sur ta moitié', style: const TextStyle(color: Pal.gold, fontSize: 11))]),
        const SizedBox(height: 7),
        Wrap(spacing: 6, runSpacing: 4, alignment: WrapAlignment.center, children: [
          for (final d in available) ChoiceChip(label: Text(d['label'] as String), selected: selectedDeployment == d['id'],
            onSelected: ready ? null : (_) => setState(() => selectedDeployment = d['id'] as String)),
        ]),
        const SizedBox(height: 7),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: ready || deployed != 4 ? null : () => widget.room.sendAction('ready'),
          child: Text(ready ? 'EN ATTENTE DE L’ADVERSAIRE' : 'JE SUIS PRÊT'))),
      ]));
  }

  Widget _battleControls() => Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: const BoxDecoration(color: Color(0xFF1B2A41), border: Border(top: BorderSide(color: Colors.white12))),
    child: Row(children: [
      Expanded(child: Text(myTurn ? (selectedUnit == null ? 'Sélectionne une unité, puis une case.' : 'Choisis une case ou un ennemi à portée.')
        : 'Tour de ton adversaire…', style: const TextStyle(color: Colors.white70, fontSize: 12))),
      const SizedBox(width: 8),
      FilledButton.icon(onPressed: myTurn && !finished ? () { selectedUnit = null; widget.room.sendAction('endTurn'); } : null,
        icon: const Icon(Icons.flag), label: const Text('FIN DU TOUR')),
    ]));
}

class _RushBoardPainter extends CustomPainter {
  _RushBoardPainter({required this.map, required this.units, required this.selectedId, required this.localSide});
  final GameMap map;
  final List<Map<String, dynamic>> units;
  final String? selectedId;
  final String localSide;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / map.cols;
    final cellH = size.height / map.rows;
    final grid = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.65..color = const Color(0x884D402E);
    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.cols; x++) {
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        final terrain = map.terrainAt(Pos(x, y));
        canvas.drawRect(rect, Paint()..color = terrainColor(terrain));
        if (terrain == Terrain.fort) {
          canvas.drawRect(rect.deflate(cellW * .13), Paint()..color = Pal.gold.withAlpha(120));
          _text(canvas, '✦', Offset(rect.left, rect.top + cellH * .05), cellW * .75, const Color(0xFF6B4213));
        } else if (terrain == Terrain.oasis) {
          _text(canvas, '✿', Offset(rect.left, rect.top + cellH * .05), cellW * .65, const Color(0xFF47794D));
        } else if (terrain == Terrain.mountain) {
          _text(canvas, '▲', Offset(rect.left, rect.top + cellH * .08), cellW * .62, const Color(0xFF64594B));
        } else if (terrain == Terrain.grove) {
          _text(canvas, '♣', Offset(rect.left, rect.top + cellH * .08), cellW * .62, const Color(0xFF587344));
        }
        canvas.drawRect(rect, grid);
      }
    }
    for (final unit in units) {
      final x = unit['x'] as int, y = unit['y'] as int;
      final center = Offset((x + .5) * cellW, (y + .5) * cellH);
      final color = unit['side'] == 'host' ? Pal.player : Pal.enemy;
      final radius = math.min(cellW, cellH) * .38;
      canvas.drawCircle(center.translate(0, 1), radius, Paint()..color = Colors.black.withAlpha(90));
      canvas.drawCircle(center, radius, Paint()..color = color);
      canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.3..color = Colors.white);
      if (unit['id'] == selectedId) {
        canvas.drawCircle(center, radius + 2.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = Pal.gold);
      }
      final letter = switch (unit['type']) {'guard' => 'G', 'archer' => 'A', 'rider' => 'C', _ => 'E'};
      _text(canvas, letter, Offset(center.dx - radius * .62, center.dy - radius * .73), radius * 1.25, Colors.white);
      final hp = unit['hp'] as int;
      final hpPaint = Paint()..color = Colors.black54;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center.dx, center.dy + radius * .78),
        width: radius * 1.5, height: 2.5), const Radius.circular(2)), hpPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - radius * .75, center.dy + radius * .78,
        radius * 1.5 * (hp / 4), 2.5), const Radius.circular(2)), Paint()..color = Colors.lightGreenAccent);
    }
  }

  void _text(Canvas canvas, String value, Offset offset, double size, Color color) {
    final tp = TextPainter(text: TextSpan(text: value, style: TextStyle(fontSize: size, color: color,
      fontWeight: FontWeight.w900, shadows: const [Shadow(color: Colors.black38, blurRadius: 2)])),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, offset + Offset((size - tp.width) / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _RushBoardPainter old) => old.units != units || old.selectedId != selectedId;
}

T? _firstOrNull<T>(Iterable<T> values) => values.isEmpty ? null : values.first;
