import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeService {
  static const String themeBlue = 'blue';
  static const String themePink = 'pink';
  static const String _themeKey = 'app_theme_variant';
  static const Set<String> _supportedThemes = {
    themeBlue,
    themePink,
  };

  static final ValueNotifier<String> notifier = ValueNotifier<String>(themeBlue);

  static Future<void> init() async {
    notifier.value = await loadTheme();
  }

  static Future<void> saveTheme(String theme) async {
    final normalized = _supportedThemes.contains(theme) ? theme : themeBlue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, normalized);
    notifier.value = normalized;
  }

  static Future<String> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_themeKey);
    if (text == null || !_supportedThemes.contains(text)) {
      return themeBlue;
    }
    return text;
  }

  static Color seedColorFor(String theme) {
    switch (theme) {
      case themePink:
        return const Color(0xFFE86A9E);
      case themeBlue:
      default:
        return Colors.blue;
    }
  }

  static ThemeData buildTheme(String theme) {
    final seedColor = seedColorFor(theme);
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    if (theme == themePink) {
      final pinkSurface = const Color(0xFFFFF6FA);
      final pinkSurfaceHigh = const Color(0xFFFFEDF5);
      final pinkOutline = const Color(0xFFF1C7D9);
      return ThemeData(
        colorScheme: scheme.copyWith(
          primary: const Color(0xFFD84F88),
          secondary: const Color(0xFFF08BB4),
          surface: pinkSurface,
          surfaceContainerHighest: pinkSurfaceHigh,
          outline: pinkOutline,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBFD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFBFD),
          foregroundColor: Color(0xFF7A274A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: pinkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: pinkOutline),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: pinkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: pinkOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: pinkOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD84F88), width: 1.4),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF7A274A),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD84F88),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC14379),
            side: BorderSide(color: pinkOutline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFFC14379),
        ),
        useMaterial3: true,
      );
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
    );
  }
}
