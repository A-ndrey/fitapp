import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const energyOrange = Color(0xFFFF7A1A);
  static const pulseLime = Color(0xFFB7F34A);
  static const recoveryBlue = Color(0xFF42C8F5);
  static const deepBackground = Color(0xFF0B0F14);
  static const deepSurface = Color(0xFF121922);
  static const lightBackground = Color(0xFFF4F0E8);
  static const lightSurface = Color(0xFFFFFBF3);

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: energyOrange,
          brightness: Brightness.light,
        ).copyWith(
          primary: energyOrange,
          secondary: pulseLime,
          tertiary: recoveryBlue,
          surface: lightSurface,
        );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: energyOrange,
          brightness: Brightness.dark,
        ).copyWith(
          primary: energyOrange,
          secondary: pulseLime,
          tertiary: recoveryBlue,
          surface: deepSurface,
        );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: deepBackground,
      useMaterial3: true,
    );
  }
}
