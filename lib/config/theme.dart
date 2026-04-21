import 'package:flutter/material.dart';

class HumphTheme {
  static const Color primary = Color(0xFFFF6F00);
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF262626);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3A3A3A);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          surface: surface,
          onPrimary: Colors.white,
          onSurface: onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: onBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: onBackground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: background,
          selectedItemColor: onBackground,
          unselectedItemColor: onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 0.5,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: onSurfaceVariant),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceVariant,
          selectedColor: onBackground,
          labelStyle: const TextStyle(color: onSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: divider),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: onBackground),
          bodyLarge: TextStyle(color: onSurface),
          bodyMedium: TextStyle(color: onSurface),
          bodySmall: TextStyle(color: onSurfaceVariant),
          labelSmall: TextStyle(color: onSurfaceVariant),
        ),
      );
}
