import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeController({ThemeMode initialThemeMode = ThemeMode.light})
      : _themeMode = initialThemeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
