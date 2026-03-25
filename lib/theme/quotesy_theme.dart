import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QColors — single source of truth for every colour in the app.
// Import this instead of hardcoding hex values anywhere.
// ─────────────────────────────────────────────────────────────────────────────
class QColors {
  QColors._();

  // Backgrounds
  static const obsidian    = Color(0xFF050505);
  static const surface     = Color(0xFF111111); // nav bar pill, cards
  static const cardBase    = Color(0xFF080604); // explore category cards

  // Text hierarchy
  static const textPrimary = Colors.white;
  static const textMuted   = Color(0x99FFFFFF); // ~white60
  static const textSubtle  = Color(0x61FFFFFF); // ~white38
  static const textGhost   = Color(0x3DFFFFFF); // ~white24

  // Accent — Dark Academia amber/gold
  static const amber       = Color(0xFFB8860B); // borders, pill fill base
  static const amberGlow   = Color(0xFFD4A017); // active icons + text
  static const amberSubtle = Color(0x29B8860B); // ~16% — tab background

  // Borders
  static const borderSubtle = Color(0x12FFFFFF); // ~white7
  static const borderMid    = Color(0x1FFFFFFF); // ~white12

  // Divider
  static const divider = Color(0x26FFFFFF); // ~white15
}

// ─────────────────────────────────────────────────────────────────────────────
// darkMode — the single ThemeData instance for the whole app.
// ─────────────────────────────────────────────────────────────────────────────
final ThemeData darkMode = () {
  const colorScheme = ColorScheme.dark(
    surface:           QColors.obsidian,
    primary:           QColors.textPrimary,
    secondary:         QColors.surface,
    tertiary:          Color(0xFF424242),
    tertiaryContainer: Color(0xFF757575),
    inversePrimary:    Color(0x99FFFFFF),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: QColors.obsidian,
    fontFamily: 'Inter',

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),

    textTheme: const TextTheme(
      // Large quote text
      displayLarge: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: QColors.textPrimary,
      ),
      // Quote body — italic Playfair
      displayMedium: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 20,
        fontStyle: FontStyle.italic,
        height: 1.4,
        color: QColors.textPrimary,
      ),
      // Explore card titles
      headlineMedium: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: QColors.textPrimary,
        height: 1.15,
      ),
      // Author names — tracked caps
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: QColors.textSubtle,
      ),
      // Subtitles and body copy
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: QColors.textMuted,
        height: 1.5,
      ),
      // Small category tags — POETRY, PHILOSOPHY etc.
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.5,
        color: QColors.textSubtle,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: QColors.surface,
      hintStyle: const TextStyle(color: Color(0xFF424242)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: QColors.surface, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: QColors.surface, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: QColors.obsidian,
      selectedItemColor: QColors.amberGlow,
      unselectedItemColor: QColors.textGhost,
    ),

    dividerTheme: const DividerThemeData(
      color: QColors.divider,
      thickness: 1,
    ),
  );
}();