import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String language;
  final bool isOffline;
  final bool dataSaverMode;

  SettingsState({
    this.themeMode = ThemeMode.dark,
    this.language = 'English',
    this.isOffline = false,
    this.dataSaverMode = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? isOffline,
    bool? dataSaverMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      isOffline: isOffline ?? this.isOffline,
      dataSaverMode: dataSaverMode ?? this.dataSaverMode,
    );
  }
}

class SettingsNotifier extends fr.Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      themeMode: _parseThemeMode(prefs.getString('themeMode') ?? 'dark'),
      language: prefs.getString('appLanguage') ?? 'English',
      isOffline: prefs.getBool('simulateSlowNetwork') ?? false,
      dataSaverMode: prefs.getBool('dataSaverMode') ?? false,
    );
  }

  ThemeMode _parseThemeMode(String theme) {
    switch (theme) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  void setOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('simulateSlowNetwork', value);
    state = state.copyWith(isOffline: value);
  }

  void setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    state = state.copyWith(themeMode: mode);
  }
}

final settingsProvider = fr.NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
