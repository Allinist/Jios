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
}
