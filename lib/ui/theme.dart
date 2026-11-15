import 'package:flutter/material.dart';

import '../models/terrain.dart';

class Pal {
  static const sand = Color(0xFFEFE0BC);
  static const parchment = Color(0xFFFAF1DA);
  static const ink = Color(0xFF3B2F1E);
  static const green = Color(0xFF1F4D3A);
  static const bronze = Color(0xFFA67C37);
  static const gold = Color(0xFFE0A526);
  static const player = Color(0xFF1F6B4A);
  static const enemy = Color(0xFF9A3B2B);
  static const move = Color(0xFF2E9E5B);
  static const attack = Color(0xFFD64530);
  static const place = Color(0xFF2F7DD1);
  static const target = Color(0xFFE0A526);
  static const turquoise = Color(0xFF1C8C8C);
  static const terracotta = Color(0xFFB5523B);
  static const indigo = Color(0xFF1B2A41);
}

Color terrainColor(Terrain t) => switch (t) {
      Terrain.plains => const Color(0xFFEAD8A8),
      Terrain.dunes => const Color(0xFFE2C887),
      Terrain.grove => const Color(0xFFD3D9A4),
      Terrain.hills => const Color(0xFFD9C08F),
      Terrain.mountain => const Color(0xFFB9A58C),
      Terrain.river => const Color(0xFF7DB4CF),
      Terrain.ford => const Color(0xFFA5CBD6),
      Terrain.oasis => const Color(0xFFCFE0B4),
      Terrain.city => const Color(0xFFE6D2A4),
      Terrain.fort => const Color(0xFFDCC58F),
      Terrain.sea => const Color(0xFF2F6F9E),
      Terrain.mud => const Color(0xFFA88E62),
      Terrain.cliff => const Color(0xFF6B5238),
    };

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: Pal.green,
    primary: Pal.green,
    secondary: Pal.gold,
    surface: Pal.parchment,
  );
  return base.copyWith(
    useMaterial3: true,
    colorScheme: scheme,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
    }),
    scaffoldBackgroundColor: Pal.sand,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: Pal.indigo,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 3,
      shadowColor: Colors.black38,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 0.4),
    ),
    textTheme: base.textTheme.apply(bodyColor: Pal.ink, displayColor: Pal.ink).copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(color: Pal.indigo, fontWeight: FontWeight.w900),
      titleLarge: base.textTheme.titleLarge?.copyWith(color: Pal.indigo, fontWeight: FontWeight.w800),
      titleMedium: base.textTheme.titleMedium?.copyWith(color: Pal.ink, fontWeight: FontWeight.w700),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Pal.green,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Pal.indigo.withAlpha(70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pal.green,
        side: const BorderSide(color: Pal.bronze, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Pal.green, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0x557E6848), thickness: 1, space: 16),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Pal.indigo,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Pal.turquoise),
  );
}

/// Faint Andalusian-style eight-pointed star lattice (menu background).
class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Pal.turquoise.withAlpha(38);
    const s = 56.0;
    for (var y = 0.0; y < size.height + s; y += s) {
      for (var x = 0.0; x < size.width + s; x += s) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s * 0.7), p);
        canvas.rotate(0.7853981634);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s * 0.7), p);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter old) => false;
}
