import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state — persisted across app restarts.
enum LyrisThemeMode { light, dark, system }

class ThemeNotifier extends StateNotifier<LyrisThemeMode> {
  ThemeNotifier() : super(LyrisThemeMode.system) {
    _load();
  }

  static const _prefKey = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      state = LyrisThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => LyrisThemeMode.system,
      );
    }
  }

  Future<void> setMode(LyrisThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  ThemeMode get flutterThemeMode {
    switch (state) {
      case LyrisThemeMode.light:
        return ThemeMode.light;
      case LyrisThemeMode.dark:
        return ThemeMode.dark;
      case LyrisThemeMode.system:
        return ThemeMode.system;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, LyrisThemeMode>(
  (ref) => ThemeNotifier(),
);
