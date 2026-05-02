import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const trainingRed = Color(0xFFE6532E);
  static const adherenceOlive = Color(0xFF7F9362);
  static const steelBlue = Color(0xFF6F8798);
  static const deepBackground = Color(0xFF090B0D);
  static const deepSurface = Color(0xFF14181D);
  static const lightBackground = Color(0xFFE7E2D8);
  static const lightSurface = Color(0xFFF7F1E6);

  static const energyOrange = trainingRed;
  static const pulseLime = adherenceOlive;
  static const recoveryBlue = steelBlue;

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: trainingRed,
          brightness: Brightness.light,
        ).copyWith(
          primary: trainingRed,
          onPrimary: const Color(0xFF120806),
          secondary: adherenceOlive,
          onSecondary: const Color(0xFF0B0E08),
          tertiary: steelBlue,
          onTertiary: const Color(0xFF071014),
          surface: lightSurface,
          surfaceContainerHighest: const Color(0xFFE0D8CB),
        );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD8CFC0)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: lightBackground,
        foregroundColor: Color(0xFF1E2429),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: trainingRed,
          brightness: Brightness.dark,
        ).copyWith(
          primary: trainingRed,
          onPrimary: const Color(0xFF120806),
          secondary: adherenceOlive,
          onSecondary: const Color(0xFF0B0E08),
          tertiary: steelBlue,
          onTertiary: const Color(0xFF071014),
          surface: deepSurface,
          surfaceContainerHighest: const Color(0xFF20262C),
        );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: deepBackground,
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: deepSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF252C33)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: deepBackground,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
