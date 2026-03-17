import 'package:flutter/material.dart';

class AppTheme {
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color lightGreen = Color(0xFF52B788);
  static const Color cream = Color(0xFFF8F4E3);
  static const Color earthBrown = Color(0xFF8B5E3C);
  static const Color safeGreen = Color(0xFF40916C);
  static const Color warningAmber = Color(0xFFE9A319);
  static const Color dangerRed = Color(0xFFD62828);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: forestGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B3A2D),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
