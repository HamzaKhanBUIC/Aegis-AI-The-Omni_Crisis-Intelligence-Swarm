// ══════════════════════════════════════════════════════════════════════════════
// AEGIS-OMNI ADMIN WEB COMMAND CENTER — THEME
// Deep Canvas Black / Slate Gray / Cyan + Amber accent palette
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AegisAdminTheme {
  // ── Palette ─────────────────────────────────────────────────────────────────
  static const Color canvas       = Color(0xFF0B0B0C);
  static const Color slate        = Color(0xFF1C1C1E);
  static const Color slateLight   = Color(0xFF2C2C2E);
  static const Color slateDark    = Color(0xFF111113);
  static const Color cyan         = Color(0xFF00E5FF);
  static const Color cyanDim      = Color(0xFF00B8D4);
  static const Color amber        = Color(0xFFFFB300);
  static const Color amberDim     = Color(0xFFFF8F00);
  static const Color danger       = Color(0xFFFF3B30);
  static const Color success      = Color(0xFF00FF66);
  static const Color textPrimary  = Color(0xFFEFEFEF);
  static const Color textSecond   = Color(0xFF8A8A8E);
  static const Color textMuted    = Color(0xFF52525B);
  static const Color border       = Color(0xFF27272A);
  static const Color borderCyan   = Color(0xFF003B44);

  // ── Typography ───────────────────────────────────────────────────────────────
  static TextStyle mono({
    double size = 12,
    Color color = textSecond,
    FontWeight weight = FontWeight.normal,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  static ThemeData get theme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: amber,
        surface: slate,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(color: textSecond, fontSize: 13),
        bodySmall: GoogleFonts.inter(color: textMuted, fontSize: 11),
      ),
      dividerColor: border,
      dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
    );
  }
}
