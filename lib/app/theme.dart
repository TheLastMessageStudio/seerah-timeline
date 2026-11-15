import 'package:flutter/material.dart';

const _green = Color(0xFF124B36);
const _greenDeep = Color(0xFF0B3327);
const _parchment = Color(0xFFF4EBD8);
const _paper = Color(0xFFFBF7ED);
const _gold = Color(0xFFB28A43);
const _goldLight = Color(0xFFD7B96F);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: _green,
    brightness: b,
    surface: dark ? const Color(0xFF17251F) : _parchment,
  );
  final scheme = base.copyWith(
    primary: dark ? const Color(0xFF9BC6A8) : _green,
    onPrimary: dark ? const Color(0xFF092A1D) : Colors.white,
    secondary: dark ? const Color(0xFFD6B56E) : _gold,
    onSecondary: dark ? const Color(0xFF30230B) : Colors.white,
    tertiary: dark ? const Color(0xFFC8A66A) : const Color(0xFF8A6B35),
    surface: dark ? const Color(0xFF17251F) : _parchment,
    surfaceContainerLowest: dark ? const Color(0xFF101A16) : _paper,
    surfaceContainerLow: dark ? const Color(0xFF1C2B24) : const Color(0xFFF8F1E3),
    surfaceContainer: dark ? const Color(0xFF22342B) : const Color(0xFFEFE3CC),
    outline: dark ? const Color(0xFF64786C) : const Color(0xFFB6A783),
  );
  final text = ThemeData(brightness: b).textTheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardColor: dark ? const Color(0xFF203128) : _paper,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? _greenDeep : _green,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: .1),
      iconTheme: const IconThemeData(color: Color(0xFFF2E6C9)),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: dark ? const Color(0xFF15231D) : const Color(0xFFFBF7ED),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      width: 312,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: dark ? _goldLight : _green,
      selectedColor: dark ? _goldLight : _green,
      selectedTileColor: dark ? const Color(0xFF263A30) : const Color(0xFFECE1C9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 28,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xFF17251F) : _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF203128) : _paper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.secondary, width: 1.7),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outline.withOpacity(0.35)),
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.45, fontFamily: 'serif'),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.16, fontFamily: 'serif'),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.2, fontFamily: 'serif'),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: .05),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.72, fontFamily: 'serif'),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.55),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: .15),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 78,
      backgroundColor: dark ? const Color(0xFF101A16) : const Color(0xFFF8F1E3),
      indicatorColor: dark ? const Color(0xFF365543) : const Color(0xFFE3D2AD),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: MaterialStateProperty.resolveWith((states) => TextStyle(
        fontSize: 12,
        fontWeight: states.contains(MaterialState.selected) ? FontWeight.w700 : FontWeight.w500,
      )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? const Color(0xFF2A3D32) : const Color(0xFFECE0C6),
      side: BorderSide(color: scheme.secondary.withOpacity(0.42)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
  );
}
