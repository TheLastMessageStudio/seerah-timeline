import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/game.dart';
import '../models/battlefield.dart';
import '../models/game_map.dart';
import '../models/side.dart';
import '../models/terrain.dart';
import '../models/units.dart';
import '../strings.dart';
import 'icons.dart';
import 'theme.dart';

/// A floating number (damage / heal) shown briefly above a cell.
class FxItem {
  const FxItem(this.id, this.pos, this.text, this.color);
  final int id;
  final Pos pos;
  final String text;
  final Color color;
}

class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.game,
    required this.cell,
    required this.visible,
    required this.moveCells,
    required this.attackCells,
    required this.placeCells,
    required this.targetCells,
    required this.dangerCells,
    required this.selectedUnit,
    required this.fx,
    required this.onTap,
  });

  final Game game;
  final double cell;
  final Set<Pos> visible;
  final Set<Pos> moveCells;
  final Set<Pos> attackCells;
  final Set<Pos> placeCells;
  final Set<Pos> targetCells;
  final Set<Pos> dangerCells;
  final Unit? selectedUnit;
  final List<FxItem> fx;
  final ValueChanged<Pos> onTap;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  // Taps are detected with a raw Listener so that InteractiveViewer keeps
  // its pinch/pan recognizers even when the gesture starts on the map.
  final Map<int, Offset> _down = {};
  Offset? _start;
  DateTime? _startTime;
  bool _multi = false;
  bool _moved = false;
  bool _bgOk = true;

  void _onDown(PointerDownEvent e) {
    _down[e.pointer] = e.localPosition;
    if (_down.length == 1) {
      _start = e.localPosition;
      _startTime = DateTime.now();
      _multi = false;
      _moved = false;
    } else {
      _multi = true;
    }
  }

  void _onMove(PointerMoveEvent e) {
    final s = _start;
    if (s != null && (e.localPosition - s).distance > 10) _moved = true;
  }

  void _onUp(PointerUpEvent e) {
    final wasSingle = _down.length == 1;
    _down.remove(e.pointer);
    if (wasSingle && !_multi && !_moved) {
      final t = _startTime;
      if (t != null && DateTime.now().difference(t).inMilliseconds < 450) {
        final cell = widget.cell;
        final p = Pos((e.localPosition.dx / cell).floor(), (e.localPosition.dy / cell).floor());
        if (widget.game.map.inBounds(p)) widget.onTap(p);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final cell = widget.cell;
    final map = game.map;
    final w = cell * map.cols;
    final h = cell * map.rows;
    final hasBg = map.backgroundBytes != null && _bgOk;
    final shown = game.units
        .where((u) => u.side == Side.player || game.canSee(Side.player, u))
        .toList();
    final links = <(Pos, Pos)>[];
    for (var i = 0; i < shown.length; i++) {
      for (var j = i + 1; j < shown.length; j++) {
        final a = shown[i];
        final b = shown[j];
        if (a.side == b.side && a.type.troopRole == b.type.troopRole && a.pos.dist(b.pos) == 1) {
          links.add((a.pos, b.pos));
        }
      }
    }
    return SizedBox(
      width: w,
      height: h,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: (e) {
          _down.remove(e.pointer);
          _multi = true;
        },
        child: Stack(
          children: [
            if (hasBg)
              Positioned.fill(
                child: Image.memory(
                  map.backgroundBytes!,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  errorBuilder: (ctx, e, st) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _bgOk) setState(() => _bgOk = false);
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            RepaintBoundary(
              child: CustomPaint(size: Size(w, h), painter: TerrainPainter(map, withBg: hasBg)),
            ),
            CustomPaint(
              size: Size(w, h),
              painter: OverlayPainter(
                game: game,
                visible: widget.visible,
                moveCells: widget.moveCells,
                attackCells: widget.attackCells,
                placeCells: widget.placeCells,
                targetCells: widget.targetCells,
                dangerCells: widget.dangerCells,
                selected: widget.selectedUnit?.pos,
                links: links,
              ),
            ),
            for (final u in shown)
              AnimatedPositioned(
                key: ValueKey(u.id),
                duration: const Duration(milliseconds: 430),
                curve: Curves.easeInOutCubic,
                left: u.pos.c * cell,
                top: u.pos.r * cell,
                width: cell,
                height: cell,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: identical(u, widget.selectedUnit) ? 1.10 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: UnitToken(
                    unit: u,
                    size: cell,
                    selected: identical(u, widget.selectedUnit),
                    dim: u.side == Side.player &&
                        game.phase == Phase.battle &&
                        u.moved &&
                        u.attacked,
                  )),
                ),
              ),
            for (final f in widget.fx) _FxText(key: ValueKey('fx${f.id}'), item: f, cell: cell),
          ],
        ),
      ),
    );
  }
}

class _FxText extends StatelessWidget {
  const _FxText({super.key, required this.item, required this.cell});
  final FxItem item;
  final double cell;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, t, _) => Positioned(
        left: item.pos.c * cell,
        top: item.pos.r * cell - 26 * t,
        width: cell,
        child: IgnorePointer(
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(scale: .72 + (t * .48), child: Text(
              item.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: item.color,
                fontSize: cell * 0.5,
                fontWeight: FontWeight.w900,
                shadows: const [Shadow(color: Colors.white, blurRadius: 3)],
              )),
            ),
          ),
        ),
      ),
    );
  }
}

/// Unit token: a battle-map tile (green with a cross for your side, red with a
/// diamond for the enemy), with the role icon. An optional character image
/// `assets/units/<id>.png` (see the README in that folder) replaces the icon.
class UnitToken extends StatelessWidget {
  const UnitToken({
    super.key,
    required this.unit,
    required this.size,
    required this.selected,
    required this.dim,
  });

  final Unit unit;
  final double size;
  final bool selected;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final isPlayer = unit.side == Side.player;
    final hero = unit.type.named;
    final light = isPlayer ? const Color(0xFF3FA062) : const Color(0xFFC23A32);
    final deep = isPlayer ? const Color(0xFF14532D) : const Color(0xFF5E1212);
    final icon = Icon(typeIcon(unit.type), color: Colors.white, size: size * 0.40);
    final radius = size * 0.10;
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Padding(
        padding: EdgeInsets.all(size * 0.10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [light, deep],
                  ),
                  border: Border.all(
                    color: selected
                        ? Pal.gold
                        : (hero ? const Color(0xFFE8C45A) : const Color(0xFF1B1209)),
                    width: selected ? 3 : (hero ? 2.2 : 1.6),
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(1.5, 2))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius * 0.8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _TilePatternPainter(isPlayer)),
                      Image.asset(
                        'assets/units/${unit.type.id}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(child: icon),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -size * 0.06,
              bottom: -size * 0.06,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: size * 0.07, vertical: size * 0.01),
                decoration: BoxDecoration(
                  color: Pal.ink,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white70, width: 0.8),
                ),
                child: Text(
                  '${unit.hp}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.22,
                  ),
                ),
              ),
            ),
            if (unit.ambush)
              Positioned(
                left: -size * 0.04,
                top: -size * 0.04,
                child: Icon(Icons.visibility_off, size: size * 0.28, color: Pal.gold),
              ),
            if (unit.dest != null)
              Positioned(
                left: -size * 0.04,
                bottom: -size * 0.04,
                child: Icon(Icons.flag, size: size * 0.28, color: Pal.gold),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pattern of the tile: a cross for your side, a diamond for the enemy.
class _TilePatternPainter extends CustomPainter {
  _TilePatternPainter(this.player);
  final bool player;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, size.width * 0.05)
      ..color = const Color(0x55000000);
    if (player) {
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), line);
      canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), line);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(size.width / 2, size.height * 0.08)
          ..lineTo(size.width * 0.92, size.height / 2)
          ..lineTo(size.width / 2, size.height * 0.92)
          ..lineTo(size.width * 0.08, size.height / 2)
          ..close(),
        line,
      );
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0x44FFFFFF));
  }

  @override
  bool shouldRepaint(covariant _TilePatternPainter old) => old.player != player;
}

// ------------------------------------------------------------------ painters

void _drawText(Canvas canvas, String s, Offset o, double size, Color color, {bool center = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontSize: size.clamp(7.0, 16.0).toDouble(),
        color: color,
        fontWeight: FontWeight.w800,
        shadows: const [Shadow(color: Color(0xCCFAF1DA), blurRadius: 2)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center ? o - Offset(tp.width / 2, 0) : o);
}

/// Static terrain: painted once and cached by the RepaintBoundary.
class TerrainPainter extends CustomPainter {
  TerrainPainter(this.map, {this.withBg = false});
  final GameMap map;
  final bool withBg; // a picture is drawn under: only draw light symbols

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / map.cols;
    final ch = size.height / map.rows;
    if (withBg) {
      canvas.saveLayer(Offset.zero & size, Paint()..color = const Color(0x8CFFFFFF));
      for (var r = 0; r < map.rows; r++) {
        for (var c = 0; c < map.cols; c++) {
          _terrain(canvas, Rect.fromLTWH(c * cw, r * ch, cw, ch), map.terrainAt(Pos(c, r)), c * 31 + r * 17);
        }
      }
      canvas.restore();
    } else {
      _paintRich(canvas, cw, ch);
    }
    final grid = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var c = 0; c <= map.cols; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, size.height), grid);
    }
    for (var r = 0; r <= map.rows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.width, r * ch), grid);
    }
    for (final p in map.roads) {
      canvas.drawCircle(Offset((p.c + 0.5) * cw, (p.r + 0.5) * ch), cw * 0.1, Paint()..color = const Color(0xCC7A4B2A));
    }
    for (final city in map.cities) {
      _city(canvas, city, cw, ch);
    }
    // Ornamental frame.
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Pal.gold);
    canvas.drawRect(
        (Offset.zero & size).deflate(8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Pal.turquoise);
  }

  static int _hash(int c, int r) => ((c * 73856093) ^ (r * 19349663) ^ 0x5bd1e995) & 0x7fffffff;

  /// Irregular rocky outline around ([cx],[cy]).
  Path _blob(double cx, double cy, double rx, double ry, int h) {
    final path = Path();
    const n = 9;
    for (var i = 0; i < n; i++) {
      final a = 2 * pi * i / n;
      final k = 0.72 + 0.4 * (((h >> (i * 2)) & 7) / 7.0);
      final x = cx + cos(a) * rx * k;
      final y = cy + sin(a) * ry * k;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// Hand-painted look: sand, rocky massifs, rounded hills, shrub clusters.
  void _paintRich(Canvas canvas, double cw, double ch) {
    const plain = {Terrain.plains, Terrain.city, Terrain.grove, Terrain.hills, Terrain.mountain, Terrain.cliff};
    const sandA = Color(0xFFDCC796);
    const sandB = Color(0xFFCDB583);
    // 1. ground
    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        final t = map.terrainAt(Pos(c, r));
        final h = _hash(c, r);
        final rect = Rect.fromLTWH(c * cw, r * ch, cw + 0.6, ch + 0.6);
        if (plain.contains(t)) {
          canvas.drawRect(rect, Paint()..color = Color.lerp(sandA, sandB, (h % 100) / 100)!);
        } else {
          _terrain(canvas, rect, t, c * 31 + r * 17);
        }
      }
    }
    // 2. soft light and shade blotches, like worn ground
    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        final h = _hash(c, r);
        if (h % 6 != 0) continue;
        if (!plain.contains(map.terrainAt(Pos(c, r)))) continue;
        canvas.drawCircle(
          Offset((c + 0.5 + ((h >> 4) % 10 - 5) / 12) * cw, (r + 0.5 + ((h >> 8) % 10 - 5) / 12) * ch),
          cw * 1.1,
          Paint()
            ..color = (h % 12 == 0) ? const Color(0x16FFFFFF) : const Color(0x14604020)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.7),
        );
      }
    }
    // 3. hills
    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        if (map.terrainAt(Pos(c, r)) != Terrain.hills) continue;
        final h = _hash(c, r);
        final cx = (c + 0.5) * cw;
        final cy = (r + 0.55) * ch;
        canvas.drawOval(Rect.fromCenter(center: Offset(cx + cw * 0.05, cy + ch * 0.18), width: cw * 0.95, height: ch * 0.5),
            Paint()..color = const Color(0x30402810));
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: cw * 0.92, height: ch * 0.62),
            Paint()..color = const Color(0xFFBFA472));
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - cw * 0.1, cy - ch * 0.08), width: cw * 0.6, height: ch * 0.34),
            Paint()..color = const Color(0xFFD9C595));
        if (h % 3 == 0) {
          canvas.drawOval(Rect.fromCenter(center: Offset(cx + cw * 0.22, cy + ch * 0.2), width: cw * 0.34, height: ch * 0.2),
              Paint()..color = const Color(0xFFAA8E5E));
        }
      }
    }
    // 4. mountains and cliffs: merged rocky massifs
    for (var pass = 0; pass < 2; pass++) {
      for (var r = 0; r < map.rows; r++) {
        for (var c = 0; c < map.cols; c++) {
          final t = map.terrainAt(Pos(c, r));
          if (t != Terrain.mountain && t != Terrain.cliff) continue;
          final h = _hash(c, r);
          final cx = (c + 0.5) * cw;
          final cy = (r + 0.5) * ch;
          final path = _blob(cx, cy, cw * 0.66, ch * 0.66, h);
          if (pass == 0) {
            canvas.drawPath(path.shift(Offset(cw * 0.07, ch * 0.09)), Paint()..color = const Color(0x38201008));
            canvas.drawPath(path, Paint()..color = t == Terrain.cliff ? const Color(0xFF4B3E32) : const Color(0xFF7A6753));
          } else {
            final dark = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1.0, cw * 0.04)
              ..strokeCap = StrokeCap.round
              ..color = const Color(0xAA2E2318);
            final lite = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1.0, cw * 0.035)
              ..strokeCap = StrokeCap.round
              ..color = t == Terrain.cliff ? const Color(0x669A8468) : const Color(0x99B49C7E);
            for (var i = 0; i < 3; i++) {
              final x0 = cx + (((h >> (i * 3)) & 7) - 3.5) * cw * 0.12;
              final y0 = cy + (((h >> (i * 3 + 1)) & 7) - 3.5) * ch * 0.1;
              canvas.drawPath(
                  Path()
                    ..moveTo(x0, y0 - ch * 0.28)
                    ..lineTo(x0 + cw * 0.09, y0 - ch * 0.05)
                    ..lineTo(x0 - cw * 0.05, y0 + ch * 0.12)
                    ..lineTo(x0 + cw * 0.07, y0 + ch * 0.3),
                  i == 1 ? lite : dark);
            }
            canvas.drawLine(Offset(cx - cw * 0.32, cy - ch * 0.22), Offset(cx - cw * 0.05, cy - ch * 0.4), lite);
            if (t == Terrain.cliff) {
              canvas.drawLine(Offset(cx - cw * 0.3, cy + ch * 0.1), Offset(cx + cw * 0.3, cy + ch * 0.28), dark);
            }
          }
        }
      }
    }
    // 5. shrub clusters
    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        if (map.terrainAt(Pos(c, r)) != Terrain.grove) continue;
        final h = _hash(c, r);
        for (var i = 0; i < 8; i++) {
          final ox = ((h >> (i * 3)) & 7) / 7.0;
          final oy = ((h >> (i * 3 + 1)) & 7) / 7.0;
          final center = Offset((c + 0.14 + 0.72 * ox) * cw, (r + 0.14 + 0.72 * oy) * ch);
          final rad = cw * (0.09 + 0.05 * (((h >> i) & 3) / 3.0));
          canvas.drawCircle(center + Offset(cw * 0.02, ch * 0.03), rad + 1, Paint()..color = const Color(0x40201808));
          canvas.drawCircle(center, rad, Paint()..color = const Color(0xFF55632A));
          canvas.drawCircle(center - Offset(rad * 0.25, rad * 0.25), rad * 0.55, Paint()..color = const Color(0xFF7D8B3C));
        }
      }
    }
  }

  void _drawCamp(Canvas canvas, City city, double cw, double ch) {
    var minC = 1 << 20, maxC = -1, minR = 1 << 20, maxR = -1;
    for (final p in city.cells) {
      minC = min(minC, p.c);
      maxC = max(maxC, p.c);
      minR = min(minR, p.r);
      maxR = max(maxR, p.r);
    }
    final box = Rect.fromLTRB(minC * cw, minR * ch, (maxC + 1) * cw, (maxR + 1) * ch).deflate(cw * 0.08);
    canvas.drawRect(box.shift(Offset(cw * 0.06, ch * 0.08)), Paint()..color = const Color(0x40201008));
    canvas.drawRect(box, Paint()..color = const Color(0xFFC9AB72));
    final bead = Paint()..color = const Color(0xFF9B3F2F);
    final beadDark = Paint()..color = const Color(0xFF5C2A20);
    final step = max(4.0, cw * 0.17);
    final rad = step * 0.42;
    void beadAt(double x, double y) {
      canvas.drawCircle(Offset(x + 0.8, y + 0.8), rad, beadDark);
      canvas.drawCircle(Offset(x, y), rad, bead);
    }
    for (var x = box.left; x <= box.right + 0.1; x += step) {
      beadAt(x, box.top);
      beadAt(x, box.bottom);
    }
    for (var y = box.top + step; y < box.bottom - 0.1; y += step) {
      beadAt(box.left, y);
      beadAt(box.right, y);
    }
    for (final p in city.cells) {
      if (p == city.citadel) continue;
      final cx = (p.c + 0.5) * cw;
      final cy = (p.r + 0.56) * ch;
      final tw = cw * 0.24;
      final th = ch * 0.34;
      canvas.drawPath(
          Path()
            ..moveTo(cx, cy - th)
            ..lineTo(cx + tw, cy + th * 0.6)
            ..lineTo(cx - tw, cy + th * 0.6)
            ..close(),
          Paint()..color = const Color(0xFFF1EBDD));
      canvas.drawPath(
          Path()
            ..moveTo(cx, cy - th)
            ..lineTo(cx + tw, cy + th * 0.6)
            ..lineTo(cx + tw * 0.1, cy + th * 0.6)
            ..close(),
          Paint()..color = const Color(0x33000000));
    }
    final c0 = Offset((city.citadel.c + 0.5) * cw, (city.citadel.r + 0.5) * ch);
    canvas.drawCircle(c0, cw * 0.34,
        Paint()
          ..color = const Color(0x66FFC83C)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.18));
    canvas.drawCircle(c0, cw * 0.09, Paint()..color = const Color(0xFFFFB020));
  }

  void _city(Canvas canvas, City city, double cw, double ch) {
    final cr = Rect.fromLTWH(city.citadel.c * cw, city.citadel.r * ch, cw, ch);
    if (map.bgCamps.contains(city.id)) {
      // The picture already shows this camp: only its name is added.
      _drawText(canvas, city.name, Offset(cr.center.dx, cr.top - ch * 1.6), cw * 0.34, Pal.ink, center: true);
      return;
    }
    _drawCamp(canvas, city, cw, ch);
    _drawText(canvas, city.name, Offset(cr.center.dx, cr.top - ch * 0.62), cw * 0.34, Pal.ink, center: true);
  }

  void _terrain(Canvas canvas, Rect r, Terrain t, int hash) {
    if (withBg && (t == Terrain.plains || t == Terrain.city)) return;
    if (!withBg) canvas.drawRect(r, Paint()..color = terrainColor(t));
    final w = r.width;
    final h = r.height;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x55A67C37);
    switch (t) {
      case Terrain.plains:
        if (hash % 5 == 0) {
          final dot = Paint()..color = const Color(0x44A67C37);
          canvas.drawCircle(Offset(r.left + w * 0.3, r.top + h * 0.6), w * 0.03, dot);
          canvas.drawCircle(Offset(r.left + w * 0.7, r.top + h * 0.35), w * 0.03, dot);
        }
      case Terrain.dunes:
        for (var i = 0; i < 2; i++) {
          final y = r.top + h * (0.4 + 0.3 * i);
          canvas.drawPath(
            Path()
              ..moveTo(r.left + w * 0.1, y)
              ..quadraticBezierTo(r.left + w * 0.3, y - h * 0.15, r.left + w * 0.5, y)
              ..quadraticBezierTo(r.left + w * 0.7, y + h * 0.15, r.left + w * 0.9, y),
            line,
          );
        }
      case Terrain.grove:
        final trunk = Paint()
          ..color = const Color(0xFF6B4F2A)
          ..strokeWidth = 1.5;
        final leaf = Paint()..color = const Color(0xFF3F7A3C);
        for (final o in [const Offset(0.3, 0.4), const Offset(0.68, 0.34), const Offset(0.5, 0.72)]) {
          final c = Offset(r.left + w * o.dx, r.top + h * o.dy);
          canvas.drawLine(c, c + Offset(0, h * 0.2), trunk);
          canvas.drawCircle(c, w * 0.14, leaf);
        }
      case Terrain.hills:
        canvas.drawArc(Rect.fromLTWH(r.left + w * 0.05, r.top + h * 0.35, w * 0.55, h * 0.8), pi, pi, true,
            Paint()..color = const Color(0xFFB59468));
        canvas.drawArc(Rect.fromLTWH(r.left + w * 0.4, r.top + h * 0.2, w * 0.55, h * 1.0), pi, pi, true,
            Paint()..color = const Color(0xFFA6845A));
      case Terrain.mountain:
        canvas.drawPath(
          Path()
            ..moveTo(r.left + w * 0.04, r.bottom - h * 0.1)
            ..lineTo(r.left + w * 0.36, r.top + h * 0.12)
            ..lineTo(r.left + w * 0.68, r.bottom - h * 0.1)
            ..close(),
          Paint()..color = const Color(0xFF6E5F52),
        );
        canvas.drawPath(
          Path()
            ..moveTo(r.left + w * 0.45, r.bottom - h * 0.1)
            ..lineTo(r.left + w * 0.72, r.top + h * 0.3)
            ..lineTo(r.left + w * 0.97, r.bottom - h * 0.1)
            ..close(),
          Paint()..color = const Color(0xFF857363),
        );
        canvas.drawPath(
          Path()
            ..moveTo(r.left + w * 0.28, r.top + h * 0.3)
            ..lineTo(r.left + w * 0.36, r.top + h * 0.12)
            ..lineTo(r.left + w * 0.44, r.top + h * 0.3)
            ..close(),
          Paint()..color = Colors.white70,
        );
      case Terrain.river:
      case Terrain.sea:
        final wave = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = Colors.white54;
        final off = (hash % 3) * 0.08;
        for (var i = 0; i < 2; i++) {
          final y = r.top + h * (0.3 + off + 0.35 * i);
          canvas.drawPath(
            Path()
              ..moveTo(r.left + w * 0.1, y)
              ..quadraticBezierTo(r.left + w * 0.3, y - h * 0.12, r.left + w * 0.5, y)
              ..quadraticBezierTo(r.left + w * 0.7, y + h * 0.12, r.left + w * 0.9, y),
            wave,
          );
        }
      case Terrain.ford:
        final stone = Paint()..color = const Color(0xFFD8C79A);
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(r.left + w * (0.12 + 0.28 * i), r.top + h * 0.38, w * 0.2, h * 0.24),
                const Radius.circular(3)),
            stone,
          );
        }
      case Terrain.oasis:
        canvas.drawOval(
          Rect.fromCenter(center: r.center, width: w * 0.62, height: h * 0.5),
          Paint()..color = const Color(0xFF4FA6A0),
        );
        final palm = Paint()..color = const Color(0xFF2F6B3A);
        canvas.drawCircle(Offset(r.left + w * 0.22, r.top + h * 0.28), w * 0.09, palm);
        canvas.drawCircle(Offset(r.left + w * 0.8, r.top + h * 0.3), w * 0.08, palm);
        canvas.drawCircle(Offset(r.left + w * 0.7, r.top + h * 0.78), w * 0.08, palm);
      case Terrain.cliff:
        final hatch = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF3B2F1E);
        for (var i = 0; i < 4; i++) {
          final x = r.left + w * (0.1 + 0.27 * i);
          canvas.drawLine(Offset(x, r.bottom - h * 0.1), Offset(x + w * 0.25, r.top + h * 0.1), hatch);
        }
      case Terrain.mud:
        final puddle = Paint()..color = const Color(0x667A6240);
        canvas.drawOval(Rect.fromLTWH(r.left + w * 0.15, r.top + h * 0.55, w * 0.35, h * 0.2), puddle);
        canvas.drawOval(Rect.fromLTWH(r.left + w * 0.55, r.top + h * 0.25, w * 0.3, h * 0.18), puddle);
      case Terrain.city:
        break; // drawn by _city
      case Terrain.fort:
        final wall = Paint()..color = const Color(0xFF8A6A2F);
        canvas.drawRect(Rect.fromLTWH(r.left + w * 0.2, r.top + h * 0.35, w * 0.6, h * 0.5), wall);
        for (var i = 0; i < 3; i++) {
          canvas.drawRect(Rect.fromLTWH(r.left + w * (0.2 + i * 0.24), r.top + h * 0.24, w * 0.12, h * 0.11), wall);
        }
    }
  }

  @override
  bool shouldRepaint(covariant TerrainPainter old) => !identical(old.map, map) || old.withBg != withBg;
}

/// Dynamic layer: territories, banners, objectives, fog, highlights, links.
class OverlayPainter extends CustomPainter {
  OverlayPainter({
    required this.game,
    required this.visible,
    required this.moveCells,
    required this.attackCells,
    required this.placeCells,
    required this.targetCells,
    required this.dangerCells,
    required this.selected,
    required this.links,
  });

  final Game game;
  final Set<Pos> visible;
  final Set<Pos> moveCells;
  final Set<Pos> attackCells;
  final Set<Pos> placeCells;
  final Set<Pos> targetCells;
  final Set<Pos> dangerCells;
  final Pos? selected;
  final List<(Pos, Pos)> links;

  @override
  void paint(Canvas canvas, Size size) {
    final map = game.map;
    final cw = size.width / map.cols;
    final ch = size.height / map.rows;
    Rect rectOf(Pos p) => Rect.fromLTWH(p.c * cw, p.r * ch, cw, ch);
    Offset centerOf(Pos p) => Offset((p.c + 0.5) * cw, (p.r + 0.5) * ch);

    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        final p = Pos(c, r);
        if (map.terrainAt(p).impassable) continue;
        final z = map.zoneOf(p);
        if (z != null) {
          canvas.drawRect(rectOf(p), Paint()..color = (z == Side.player ? Pal.player : Pal.enemy).withAlpha(34));
        }
      }
    }
    // conquered territory: blue = yours, red = enemy (lost when fog returns)
    game.territory.forEach((p, side) {
      canvas.drawRect(rectOf(p),
          Paint()..color = (side == Side.player ? Pal.player : Pal.enemy).withAlpha(85));
    });
    final pc = map.playerCapital.citadel;
    final ec = map.enemyCapital.citadel;
    if (map.playerZone == null) {
      _drawText(canvas, tr('zone_you'), centerOf(pc) + Offset(0, ch * (map.zoneRadius + 0.2)), cw * 0.4, Pal.player,
          center: true);
      _drawText(canvas, tr('zone_enemy'), centerOf(ec) - Offset(0, ch * (map.zoneRadius + 0.9)), cw * 0.4, Pal.enemy,
          center: true);
    }

    game.cityOwner.forEach((city, owner) {
      final r = rectOf(city.citadel);
      final color = owner == null ? Colors.grey.shade600 : (owner == Side.player ? Pal.player : Pal.enemy);
      canvas.drawLine(
          Offset(r.left + cw * 0.12, r.top + ch * 0.05),
          Offset(r.left + cw * 0.12, r.top + ch * 0.45),
          Paint()
            ..color = Pal.ink
            ..strokeWidth = 1.5);
      canvas.drawPath(
        Path()
          ..moveTo(r.left + cw * 0.12, r.top + ch * 0.05)
          ..lineTo(r.left + cw * 0.38, r.top + ch * 0.15)
          ..lineTo(r.left + cw * 0.12, r.top + ch * 0.25)
          ..close(),
        Paint()..color = color,
      );
    });

    final goal = game.mode != GameMode.messenger ? map.enemyCapital : map.messageCity;
    canvas.drawCircle(
        centerOf(goal.citadel),
        cw * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = game.mode != GameMode.messenger ? Pal.gold : const Color(0xFF6A4FB6));

    final fog = Paint()..color = const Color(0x99101820);
    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        if (!visible.contains(Pos(c, r))) canvas.drawRect(rectOf(Pos(c, r)), fog);
      }
    }

    for (final p in dangerCells) {
      canvas.drawRect(rectOf(p).deflate(1), Paint()..color = Pal.attack.withAlpha(55));
    }
    for (final p in placeCells) {
      final r = rectOf(p);
      canvas.drawRect(r.deflate(1), Paint()..color = Pal.place.withAlpha(60));
      canvas.drawCircle(r.center, cw * 0.1, Paint()..color = Pal.place);
    }
    for (final p in moveCells) {
      final r = rectOf(p);
      canvas.drawRect(r.deflate(1), Paint()..color = Pal.move.withAlpha(45));
      canvas.drawCircle(r.center, cw * 0.16, Paint()..color = Pal.move.withAlpha(230));
    }
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final p in targetCells) {
      final r = rectOf(p);
      canvas.drawRect(r.deflate(1), Paint()..color = Pal.target.withAlpha(60));
      canvas.drawCircle(r.center, cw * 0.42, ringPaint..color = Pal.target);
    }
    for (final p in attackCells) {
      final r = rectOf(p);
      canvas.drawRect(r.deflate(1), Paint()..color = Pal.attack.withAlpha(60));
      canvas.drawCircle(r.center, cw * 0.44, ringPaint..color = Pal.attack);
    }

    final linkPaint = Paint()
      ..color = Pal.gold
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final l in links) {
      canvas.drawLine(centerOf(l.$1), centerOf(l.$2), linkPaint);
    }
    // standing march orders: dashed line and a flag on the destination
    for (final u in game.unitsOf(Side.player)) {
      final d = u.dest;
      if (d == null) continue;
      final a = centerOf(u.pos);
      final b = centerOf(d);
      final dash = Paint()
        ..color = Pal.gold
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final len = (b - a).distance;
      for (var t = 0.0; t < len; t += 12) {
        final f0 = t / len;
        final f1 = min(t + 6, len) / len;
        canvas.drawLine(Offset.lerp(a, b, f0)!, Offset.lerp(a, b, f1)!, dash);
      }
      canvas.drawLine(b, b + Offset(0, -ch * 0.42), Paint()..color = Pal.ink..strokeWidth = 2);
      canvas.drawPath(
          Path()
            ..moveTo(b.dx, b.dy - ch * 0.42)
            ..lineTo(b.dx + cw * 0.3, b.dy - ch * 0.32)
            ..lineTo(b.dx, b.dy - ch * 0.22)
            ..close(),
          Paint()..color = Pal.gold);
    }
    if (selected != null) {
      canvas.drawRect(
          rectOf(selected!).deflate(1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Pal.gold);
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter old) => true;
}

// ------------------------------------------------------------------ mini-map

class MiniMap extends StatelessWidget {
  const MiniMap({super.key, required this.game, required this.onTap});
  final Game game;
  final ValueChanged<Pos> onTap;

  @override
  Widget build(BuildContext context) {
    final map = game.map;
    const w = 78.0;
    final h = w * map.rows / map.cols;
    return GestureDetector(
      onTapUp: (d) {
        final p = Pos((d.localPosition.dx / w * map.cols).floor(), (d.localPosition.dy / h * map.rows).floor());
        if (map.inBounds(p)) onTap(p);
      },
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(border: Border.all(color: Pal.gold, width: 1.5)),
        child: CustomPaint(painter: _MiniPainter(game)),
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter(this.game);
  final Game game;

  @override
  void paint(Canvas canvas, Size size) {
    final map = game.map;
    final cw = size.width / map.cols;
    final ch = size.height / map.rows;
    for (var r = 0; r < map.rows; r++) {
      for (var c = 0; c < map.cols; c++) {
        canvas.drawRect(Rect.fromLTWH(c * cw, r * ch, cw + 0.3, ch + 0.3),
            Paint()..color = terrainColor(map.terrainAt(Pos(c, r))));
      }
    }
    for (final city in map.cities) {
      canvas.drawCircle(Offset((city.citadel.c + 0.5) * cw, (city.citadel.r + 0.5) * ch), cw * 0.9,
          Paint()..color = Pal.gold);
    }
    for (final u in game.units) {
      if (u.side != Side.player && !game.canSee(Side.player, u)) continue;
      canvas.drawCircle(Offset((u.pos.c + 0.5) * cw, (u.pos.r + 0.5) * ch), cw * 0.8,
          Paint()..color = u.side == Side.player ? Pal.player : Pal.enemy);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => true;
}
