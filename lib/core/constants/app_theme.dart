import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  static const Color bgDark        = Color(0xFF0A0E1A);
  static const Color surfaceDark   = Color(0xFF111827);
  static const Color cardDark      = Color(0xFF1A2235);
  static const Color borderDark    = Color(0xFF2A3550);
  static const Color cyan          = Color(0xFF00E5FF);
  static const Color green         = Color(0xFF00FF87);
  static const Color orange        = Color(0xFFFF6B2B);
  static const Color red           = Color(0xFFFF3D57);
  static const Color yellow        = Color(0xFFFFD60A);
  static const Color purple        = Color(0xFF9B59B6);
  static const Color textPrimary   = Color(0xFFE8F0FE);
  static const Color textSecondary = Color(0xFF8899BB);
  static const Color textDisabled  = Color(0xFF445566);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      surface: surfaceDark, primary: cyan, secondary: green,
      error: red, onSurface: textPrimary, onPrimary: bgDark,
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 2),
      displayMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 1.5),
      bodyLarge:     TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium:    TextStyle(color: textSecondary, fontSize: 14),
      labelSmall:    TextStyle(color: textSecondary, fontSize: 11, letterSpacing: 1.2),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark, elevation: 0, centerTitle: false,
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2),
      iconTheme: IconThemeData(color: cyan),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark, selectedItemColor: cyan,
      unselectedItemColor: textDisabled, type: BottomNavigationBarType.fixed, elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: cardDark, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderDark),
      ),
    ),
    dividerTheme: const DividerThemeData(color: borderDark, thickness: 1),
  );

  static LinearGradient cyanGradient() => const LinearGradient(
    colors: [Color(0xFF0080FF), cyan],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient greenGradient() => const LinearGradient(
    colors: [Color(0xFF00CC6A), green],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient cardGradient(Color accent) => LinearGradient(
    colors: [accent.withOpacity(0.15), accent.withOpacity(0.03)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow(Color color, {double spread = 8}) => [
    BoxShadow(color: color.withOpacity(0.4), blurRadius: spread * 2, spreadRadius: spread / 2),
    BoxShadow(color: color.withOpacity(0.15), blurRadius: spread * 4, spreadRadius: spread),
  ];
}