import 'dart:math';

import 'package:flutter/material.dart';

/// Logo of the real-time mode (Sariyya): a fortress seen through a medallion
/// with an eight-pointed star, a horseshoe-arch gate, pointed domes, pennants
/// and a crescent. Pure vector, drawn with a CustomPainter.
class SariyyaLogo extends StatelessWidget {
  const SariyyaLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _LogoPainter()));
}

class _LogoPainter extends CustomPainter {
  static const _gold = Color(0xFFE8B83A);
  static const _goldDark = Color(0xFF9C6F12);
  static const _sand = Color(0xFFF0DDAA);
  static const _sandShade = Color(0xFFCFB67A);
  static const _night = Color(0xFF0B1D2A);
  static const _teal = Color(0xFF1B4B52);
  static const _red = Color(0xFFC8402B);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    canvas.save();
    canvas.scale(k, k);

    Offset p(double x, double y) => Offset(x, y);
    final fill = Paint()..style = PaintingStyle.fill;
    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..color = c
      ..strokeWidth = w
      ..strokeJoin = StrokeJoin.round;

    // medallion
    final disc = Rect.fromCircle(center: p(50, 50), radius: 48);
    canvas.drawCircle(p(50, 52), 48, Paint()..color = Colors.black38..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(
      p(50, 50),
      48,
      fill..shader = const RadialGradient(colors: [_teal, _night], radius: 0.95).createShader(disc),
    );
    fill.shader = null;
    canvas.drawCircle(p(50, 50), 48, stroke(_gold, 3.2));
    canvas.drawCircle(p(50, 50), 44.2, stroke(_goldDark, 0.9));

    // eight-pointed star (two rotated squares)
    for (final rot in [0.0, pi / 4]) {
      canvas.save();
      canvas.translate(50, 50);
      canvas.rotate(rot);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 62, height: 62), stroke(_gold.withAlpha(120), 1.1));
      canvas.restore();
    }

    // side towers
    for (final x0 in [20.0, 68.0]) {
      final body = Rect.fromLTWH(x0, 46, 12, 34);
      canvas.drawRect(body, fill..color = _sand);
      canvas.drawRect(Rect.fromLTWH(x0 + 8, 46, 4, 34), fill..color = _sandShade);
      // crenellations
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(Rect.fromLTWH(x0 + i * 4.4, 43, 2.6, 3.2), fill..color = _sand);
      }
      // pointed dome
      final dome = Path()
        ..moveTo(x0 - 1.5, 43)
        ..cubicTo(x0 - 1.5, 36, x0 + 4, 33, x0 + 6, 27)
        ..cubicTo(x0 + 8, 33, x0 + 13.5, 36, x0 + 13.5, 43)
        ..close();
      canvas.drawPath(dome, fill..color = _teal.withAlpha(255));
      canvas.drawPath(dome, stroke(_gold, 1.2));
      // pennant
      canvas.drawLine(p(x0 + 6, 27), p(x0 + 6, 18), stroke(_goldDark, 1));
      final flag = Path()
        ..moveTo(x0 + 6, 18)
        ..lineTo(x0 + 13, 20)
        ..lineTo(x0 + 10.5, 21.8)
        ..lineTo(x0 + 13, 23.6)
        ..lineTo(x0 + 6, 25)
        ..close();
      canvas.drawPath(flag, fill..color = _red);
      // arrow slit
      canvas.drawRect(Rect.fromLTWH(x0 + 5, 54, 2, 7), fill..color = _night);
    }

    // curtain wall
    canvas.drawRect(const Rect.fromLTWH(30, 58, 40, 22), fill..color = _sand);
    canvas.drawRect(const Rect.fromLTWH(30, 74, 40, 6), fill..color = _sandShade);
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(Rect.fromLTWH(30.5 + i * 6.7, 55, 4, 3.2), fill..color = _sand);
    }

    // central keep
    canvas.drawRect(const Rect.fromLTWH(39, 40, 22, 40), fill..color = _sand);
    canvas.drawRect(const Rect.fromLTWH(53, 40, 8, 40), fill..color = _sandShade);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(39.5 + i * 5.7, 37, 3.6, 3.4), fill..color = _sand);
    }
    // central dome
    final dome = Path()
      ..moveTo(40, 37)
      ..cubicTo(40, 27, 46, 25, 50, 16)
      ..cubicTo(54, 25, 60, 27, 60, 37)
      ..close();
    canvas.drawPath(dome, fill..color = _teal);
    canvas.drawPath(dome, stroke(_gold, 1.3));

    // crescent finial
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: p(50, 11), radius: 6)),
      Path()..addOval(Rect.fromCircle(center: p(52.6, 10), radius: 5.2)),
    );
    canvas.drawPath(moon, fill..color = _gold);
    canvas.drawCircle(p(52.4, 9.6), 0.9, fill..color = _gold);

    // horseshoe-arch gate
    final gate = Path()
      ..moveTo(44, 80)
      ..lineTo(44, 66)
      ..cubicTo(41.2, 60, 45, 54, 50, 54)
      ..cubicTo(55, 54, 58.8, 60, 56, 66)
      ..lineTo(56, 80)
      ..close();
    canvas.drawPath(gate, fill..color = _night);
    canvas.drawPath(gate, stroke(_goldDark, 1.2));
    canvas.drawLine(p(50, 56), p(50, 80), stroke(_goldDark.withAlpha(150), 0.7));

    // arch band above the gate
    final band = Path()
      ..moveTo(42, 66)
      ..cubicTo(39, 58, 44, 51, 50, 51)
      ..cubicTo(56, 51, 61, 58, 58, 66);
    canvas.drawPath(band, stroke(_gold, 1.2));

    // ground line
    canvas.drawLine(p(14, 80.5), p(86, 80.5), stroke(_gold, 1.6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo + name, used on the lobby and the end screens.
class SariyyaWordmark extends StatelessWidget {
  const SariyyaWordmark({super.key, this.logoSize = 96, this.subtitle = ''});
  final double logoSize;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SariyyaLogo(size: logoSize),
      const SizedBox(height: 4),
      Text('SARIYYA',
          style: TextStyle(
            color: const Color(0xFFE8B83A),
            fontSize: logoSize * 0.28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: const [Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 2)],
          )),
      Text('سرية', style: TextStyle(color: const Color(0xFFF0DDAA), fontSize: logoSize * 0.22, height: 1.1)),
      if (subtitle.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
        ),
    ]);
  }
}
