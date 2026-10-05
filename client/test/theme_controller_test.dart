import 'package:client/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeController Tests', () {
    test('initial state defaults to light theme', () {
      final controller = ThemeController();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);
    });

    test('custom initial state', () {
      final controller = ThemeController(initialThemeMode: ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
    });

    test('setThemeMode updates state and notifies listeners', () {
      final controller = ThemeController();
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
      expect(notificationCount, 1);

      // Setting to same mode should not notify again
      controller.setThemeMode(ThemeMode.dark);
      expect(notificationCount, 1);
    });

    test('toggleTheme switches between dark and light correctly', () {
      final controller = ThemeController();
      controller.toggleTheme(true);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);

      controller.toggleTheme(false);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);
    });
  });
}
