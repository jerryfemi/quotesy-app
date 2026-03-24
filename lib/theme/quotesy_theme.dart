import 'package:flutter/material.dart';

final ThemeData darkMode = (() {
  const colorScheme = ColorScheme.dark(
    surface: Color.fromARGB(255, 18, 18, 18), // Deep Obsidian
    primary: Colors.white,                     // Primary highlights
    secondary: Color.fromARGB(255, 30, 30, 31), // Saved quote card background
    tertiary: Color.fromARGB(255, 66, 66, 66),  // Muted metadata
    tertiaryContainer: Color.fromARGB(255, 117, 117, 117),
    inversePrimary: Colors.white60,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color.fromARGB(255, 12, 12, 12),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),

    // Setting up the Local Fonts (Playfair & Inter)
    fontFamily: 'Inter',

    textTheme: const TextTheme(
      // The Quote text (Serif)
      displayLarge: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 26,
        fontStyle: FontStyle.italic,
        height: 1.4,
        color: Colors.white,
      ),
      // Cards Titles
      headlineMedium: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      // Metadata/Authors (Sans-serif)
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.white38,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: Colors.white70,
        height: 1.5,
      ),
    ),

    inputDecorationTheme: _inputDecorationTheme(colorScheme),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(255, 12, 12, 12),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white24,
    ),
  );
})();

InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
  return InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.secondary,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.secondary, width: 2),
    ),
    hintStyle: TextStyle(color: colorScheme.tertiary),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.secondary, width: 2),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
