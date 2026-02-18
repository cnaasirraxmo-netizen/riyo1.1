import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  String _language = 'English';
  bool _notificationsEnabled = true;
  String _playbackQuality = 'Auto';
  bool _isOffline = false;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isDataSaverEnabled = false;
  bool _parentalControlsEnabled = false;

  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  String get playbackQuality => _playbackQuality;
  bool get isOffline => _isOffline;
  ThemeMode get themeMode => _themeMode;
  bool get isDataSaverEnabled => _isDataSaverEnabled;
  bool get parentalControlsEnabled => _parentalControlsEnabled;

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

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleDataSaver(bool value) {
    _isDataSaverEnabled = value;
    notifyListeners();
  }

  void toggleParentalControls(bool value) {
    _parentalControlsEnabled = value;
    notifyListeners();
  }
}
