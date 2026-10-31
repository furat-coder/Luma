import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LumaThemeMode {
  system,
  light,
  dark,
}

class ThemeStore extends ChangeNotifier {
  ThemeStore._();

  static final ThemeStore instance = ThemeStore._();

  LumaThemeMode _mode = LumaThemeMode.system;

  LumaThemeMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case LumaThemeMode.light:
        return ThemeMode.light;

      case LumaThemeMode.dark:
        return ThemeMode.dark;

      case LumaThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString('themeMode');

    switch (savedMode) {
      case 'light':
        _mode = LumaThemeMode.light;
        break;

      case 'dark':
        _mode = LumaThemeMode.dark;
        break;

      default:
        _mode = LumaThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setMode(LumaThemeMode mode) async {
    _mode = mode;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'themeMode',
      mode.name,
    );

    notifyListeners();
  }
}