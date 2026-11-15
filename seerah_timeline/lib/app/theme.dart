import 'package:flutter/material.dart';

const _green = Color(0xFF0B5D3B);
const _parchment = Color(0xFFF5EFE0);

ThemeData buildTheme(Brightness b) {
  var scheme = ColorScheme.fromSeed(seedColor: _green, brightness: b);
  if (b == Brightness.light) scheme = scheme.copyWith(surface: _parchment);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
  );
}
