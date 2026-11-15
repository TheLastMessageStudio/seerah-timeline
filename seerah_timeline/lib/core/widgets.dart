import '../l10n/strings.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

String precisionLabel(String p) => tr('precision_$p');

String precisionExplain(String p) => tr('precision_${p}_x');

IconData precisionIcon(String p) => switch (p) {
      'exact' => Icons.check_circle_outline,
      'approximate' => Icons.schedule,
      _ => Icons.help_outline,
    };

class PrecisionChip extends StatelessWidget {
  final String precision;
  const PrecisionChip(this.precision, {super.key});
  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(precisionIcon(precision), size: 16),
        label: Text(precisionLabel(precision)),
        visualDensity: VisualDensity.compact,
      );
}

/// Motif décoratif non figuratif (étoile à huit branches).
class StarPainter extends CustomPainter {
  final Color color;
  StarPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    for (var k = 0; k < 2; k++) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = math.pi / 4 + k * math.pi / 4 + i * math.pi / 2;
        final pt = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
    canvas.drawCircle(c, r * 0.35, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class ScreenTitle extends StatelessWidget {
  final String text;
  const ScreenTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      );
}
