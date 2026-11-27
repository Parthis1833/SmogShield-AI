import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _preferenceKey = 'aeris_theme_mode';
  int _revision = 0;
  bool _disposed = false;

  @override
  ThemeMode build() {
    ref.onDispose(() => _disposed = true);
    unawaited(_restorePreference());
    return ThemeMode.system;
  }

  Future<void> _restorePreference() async {
    final revision = _revision;
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedValue = preferences.getString(_preferenceKey);
      if (_disposed || revision != _revision || storedValue == null) return;
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == storedValue,
        orElse: () => ThemeMode.system,
      );
    } catch (error, stackTrace) {
      debugPrint(
          'Unable to restore the saved AERIS theme preference: $error\n$stackTrace');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final previousMode = state;
    final revision = ++_revision;
    state = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(_preferenceKey, mode.name);
      if (!saved) throw StateError('The theme preference was not saved.');
    } catch (_) {
      if (!_disposed && revision == _revision) state = previousMode;
      rethrow;
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
