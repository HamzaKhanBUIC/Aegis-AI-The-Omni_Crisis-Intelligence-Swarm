import 'package:flutter/material.dart';

class DarkOpsTheme {
  static const Color background = Color(0xFF0D0D12);
  static const Color surface = Color(0xFF15151E);
  static const Color accent = Color(0xFF00FFCC); // Neon Cyan for active agents
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF8C8C9A);
  static const Color errorRed = Color(0xFFFF3366);

  static ThemeData getTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        error: errorRed,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: accent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A35), width: 1),
        ),
      ),
    );
  }
}
