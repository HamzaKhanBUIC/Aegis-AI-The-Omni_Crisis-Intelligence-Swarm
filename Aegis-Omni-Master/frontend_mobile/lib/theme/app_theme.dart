import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep Dark Mode Color Palette
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color accentCrimson = Color(0xFFFF2A2A); // Neon Crimson
  static const Color cyberBlue = Color(0xFF00E5FF); // Cyber Blue
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color surfaceColor = Color(0xFF1A1A1A);

  static ThemeData get deepDarkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: cyberBlue,
      colorScheme: const ColorScheme.dark(
        primary: cyberBlue,
        secondary: accentCrimson,
        surface: surfaceColor,
        background: backgroundDark,
        error: accentCrimson,
      ),
      textTheme: GoogleFonts.robotoMonoTextTheme().copyWith(
        displayLarge: GoogleFonts.robotoMono(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.robotoMono(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.robotoMono(color: textPrimary),
        bodyMedium: GoogleFonts.robotoMono(color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
