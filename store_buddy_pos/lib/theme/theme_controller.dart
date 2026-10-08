import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    if (saved == null) return;
    _themeMode = _modeFromName(saved);
    notifyListeners();
  }

  Future<void> setThemeByName(String name, {bool persist = true}) async {
    _themeMode = _modeFromName(name);
    notifyListeners();
    if (!persist) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _nameFromMode(_themeMode));
  }

  static ThemeMode _modeFromName(String name) {
    switch (name.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _nameFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
