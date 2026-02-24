import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _language = 'English';
  bool _notificationsEnabled = true;
  String _playbackQuality = 'Auto';
  bool _isOffline = false;
  ThemeMode _themeMode = ThemeMode.system;

  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  String get playbackQuality => _playbackQuality;
  bool get isOffline => _isOffline;
  ThemeMode get themeMode => _themeMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'English';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _playbackQuality = prefs.getString('playbackQuality') ?? 'Auto';
    _isOffline = prefs.getBool('isOffline') ?? false;

    final themeStr = prefs.getString('themeMode') ?? 'system';
    _themeMode = _parseThemeMode(themeStr);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String theme) {
    switch (theme) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(mode));
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setPlaybackQuality(String quality) {
    _playbackQuality = quality;
    notifyListeners();
  }

  void setOfflineMode(bool value) {
    _isOffline = value;
    notifyListeners();
  }
}
