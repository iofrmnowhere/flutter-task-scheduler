import 'package:flutter/material.dart';

class AppThemes{
  static final CardThemeData cardTheme = const CardThemeData(
  elevation: 0,
  color: const Color(0xFF1F1F1F),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.light,
    ).copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
    ),
    useMaterial3: true,
    cardTheme: cardTheme.copyWith(
      color: Color(0xFFF5F5F5),
      elevation: 0.5
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: Colors.white
    )
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Colors.deepOrange,
      surface: Colors.black,
      onSurface: Colors.white,
    ),
    useMaterial3: true,
  cardTheme: cardTheme

  );
}