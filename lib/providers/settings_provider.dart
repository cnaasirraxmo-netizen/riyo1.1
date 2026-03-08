import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Appearance
  ThemeMode _themeMode = ThemeMode.system;
  bool _amoledMode = false;
  bool _dynamicColor = true;
  Color _accentColor = Colors.red;
  String _posterSize = 'Medium';
  String _posterStyle = 'Rounded';
  bool _uiAnimations = true;
  bool _reduceMotion = false;

  // Notifications
  bool _newMovieAlerts = true;
  bool _trailerAlerts = true;
  bool _comingSoonReminders = true;
  bool _newEpisodeAlerts = true;
  bool _appUpdateNotifications = true;
  bool _notifyOnSavedReleased = true;
  bool _notifyOnSeriesNewEpisode = true;
  bool _enableNotificationSound = true;
  bool _enableNotificationVibration = true;
  String _notificationPriority = 'High';
  bool _quietMode = false;
  TimeOfDay _quietModeStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietModeEnd = const TimeOfDay(hour: 7, minute: 0);

  // Playback
  String _defaultVideoQuality = 'Auto';
  bool _preferWifiStreaming = true;
  bool _allowMobileDataStreaming = true;
  bool _doubleTapSeek = true;
  bool _subtitlesByDefault = false;
  bool _autoplayNextEpisode = true;
  bool _skipIntroAuto = false;
  bool _skipCreditsAuto = false;

  // Downloads
  String _downloadQuality = 'Medium';
  String _storageLocation = 'Internal';
  bool _downloadOnlyOnWifi = true;
  bool _allowMobileDataDownloads = false;
  bool _smartDownload = true;
  bool _deleteWatchedDownloads = false;
  bool _deleteOldestDownloadsAuto = false;

  // Data Saver
  bool _dataSaverMode = false;
  bool _reducePosterQuality = false;
  bool _disableAutoplayTrailers = false;
  bool _limitStreamingQuality = false;
  bool _disableBackgroundRefresh = false;
  bool _loadPostersOnlyWhenVisible = true;

  // Language
  String _appLanguage = 'English';
  String _subtitleLanguage = 'Auto detect';
  String _audioLanguagePreference = 'Original';

  // Privacy & Security
  bool _pauseWatchHistory = false;
  bool _twoFactorAuth = false;
  bool _deviceLoginAlerts = true;

  // Preferences
  List<String> _favoriteGenres = [];
  bool _hideAdultContent = false;
  bool _hideHorrorMovies = false;
  bool _hideSpoilers = true;
  bool _personalRecommendations = true;

  // Developer Options
  bool _isDeveloperModeEnabled = false;
  bool _enableDebugLogs = false;
  bool _simulateSlowNetwork = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get amoledMode => _amoledMode;
  bool get dynamicColor => _dynamicColor;
  Color get accentColor => _accentColor;
  String get posterSize => _posterSize;
  String get posterStyle => _posterStyle;
  bool get uiAnimations => _uiAnimations;
  bool get reduceMotion => _reduceMotion;

  bool get newMovieAlerts => _newMovieAlerts;
  bool get trailerAlerts => _trailerAlerts;
  bool get comingSoonReminders => _comingSoonReminders;
  bool get newEpisodeAlerts => _newEpisodeAlerts;
  bool get appUpdateNotifications => _appUpdateNotifications;
  bool get notifyOnSavedReleased => _notifyOnSavedReleased;
  bool get notifyOnSeriesNewEpisode => _notifyOnSeriesNewEpisode;
  bool get enableNotificationSound => _enableNotificationSound;
  bool get enableNotificationVibration => _enableNotificationVibration;
  String get notificationPriority => _notificationPriority;
  bool get quietMode => _quietMode;
  TimeOfDay get quietModeStart => _quietModeStart;
  TimeOfDay get quietModeEnd => _quietModeEnd;

  String get defaultVideoQuality => _defaultVideoQuality;
  bool get preferWifiStreaming => _preferWifiStreaming;
  bool get allowMobileDataStreaming => _allowMobileDataStreaming;
  bool get doubleTapSeek => _doubleTapSeek;
  bool get subtitlesByDefault => _subtitlesByDefault;
  bool get autoplayNextEpisode => _autoplayNextEpisode;
  bool get skipIntroAuto => _skipIntroAuto;
  bool get skipCreditsAuto => _skipCreditsAuto;

  String get downloadQuality => _downloadQuality;
  String get storageLocation => _storageLocation;
  bool get downloadOnlyOnWifi => _downloadOnlyOnWifi;
  bool get allowMobileDataDownloads => _allowMobileDataDownloads;
  bool get smartDownload => _smartDownload;
  bool get deleteWatchedDownloads => _deleteWatchedDownloads;
  bool get deleteOldestDownloadsAuto => _deleteOldestDownloadsAuto;

  bool get dataSaverMode => _dataSaverMode;
  bool get reducePosterQuality => _reducePosterQuality;
  bool get disableAutoplayTrailers => _disableAutoplayTrailers;
  bool get limitStreamingQuality => _limitStreamingQuality;
  bool get disableBackgroundRefresh => _disableBackgroundRefresh;
  bool get loadPostersOnlyWhenVisible => _loadPostersOnlyWhenVisible;

  String get appLanguage => _appLanguage;
  String get subtitleLanguage => _subtitleLanguage;
  String get audioLanguagePreference => _audioLanguagePreference;

  bool get pauseWatchHistory => _pauseWatchHistory;
  bool get twoFactorAuth => _twoFactorAuth;
  bool get deviceLoginAlerts => _deviceLoginAlerts;

  List<String> get favoriteGenres => _favoriteGenres;
  bool get hideAdultContent => _hideAdultContent;
  bool get hideHorrorMovies => _hideHorrorMovies;
  bool get hideSpoilers => _hideSpoilers;
  bool get personalRecommendations => _personalRecommendations;

  bool get isDeveloperModeEnabled => _isDeveloperModeEnabled;
  bool get enableDebugLogs => _enableDebugLogs;
  bool get simulateSlowNetwork => _simulateSlowNetwork;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme
    final themeStr = prefs.getString('themeMode') ?? 'system';
    _themeMode = _parseThemeMode(themeStr);
    _amoledMode = prefs.getBool('amoledMode') ?? false;
    _dynamicColor = prefs.getBool('dynamicColor') ?? true;
    _accentColor = Color(prefs.getInt('accentColor') ?? Colors.red.value);
    _posterSize = prefs.getString('posterSize') ?? 'Medium';
    _posterStyle = prefs.getString('posterStyle') ?? 'Rounded';
    _uiAnimations = prefs.getBool('uiAnimations') ?? true;
    _reduceMotion = prefs.getBool('reduceMotion') ?? false;

    // Notifications
    _newMovieAlerts = prefs.getBool('newMovieAlerts') ?? true;
    _trailerAlerts = prefs.getBool('trailerAlerts') ?? true;
    _comingSoonReminders = prefs.getBool('comingSoonReminders') ?? true;
    _newEpisodeAlerts = prefs.getBool('newEpisodeAlerts') ?? true;
    _appUpdateNotifications = prefs.getBool('appUpdateNotifications') ?? true;
    _notifyOnSavedReleased = prefs.getBool('notifyOnSavedReleased') ?? true;
    _notifyOnSeriesNewEpisode = prefs.getBool('notifyOnSeriesNewEpisode') ?? true;
    _enableNotificationSound = prefs.getBool('enableNotificationSound') ?? true;
    _enableNotificationVibration = prefs.getBool('enableNotificationVibration') ?? true;
    _notificationPriority = prefs.getString('notificationPriority') ?? 'High';
    _quietMode = prefs.getBool('quietMode') ?? false;
    _quietModeStart = _parseTimeOfDay(prefs.getString('quietModeStart'), const TimeOfDay(hour: 22, minute: 0));
    _quietModeEnd = _parseTimeOfDay(prefs.getString('quietModeEnd'), const TimeOfDay(hour: 7, minute: 0));

    // Playback
    _defaultVideoQuality = prefs.getString('defaultVideoQuality') ?? 'Auto';
    _preferWifiStreaming = prefs.getBool('preferWifiStreaming') ?? true;
    _allowMobileDataStreaming = prefs.getBool('allowMobileDataStreaming') ?? true;
    _doubleTapSeek = prefs.getBool('doubleTapSeek') ?? true;
    _subtitlesByDefault = prefs.getBool('subtitlesByDefault') ?? false;
    _autoplayNextEpisode = prefs.getBool('autoplayNextEpisode') ?? true;
    _skipIntroAuto = prefs.getBool('skipIntroAuto') ?? false;
    _skipCreditsAuto = prefs.getBool('skipCreditsAuto') ?? false;

    // Downloads
    _downloadQuality = prefs.getString('downloadQuality') ?? 'Medium';
    _storageLocation = prefs.getString('storageLocation') ?? 'Internal';
    _downloadOnlyOnWifi = prefs.getBool('downloadOnlyOnWifi') ?? true;
    _allowMobileDataDownloads = prefs.getBool('allowMobileDataDownloads') ?? false;
    _smartDownload = prefs.getBool('smartDownload') ?? true;
    _deleteWatchedDownloads = prefs.getBool('deleteWatchedDownloads') ?? false;
    _deleteOldestDownloadsAuto = prefs.getBool('deleteOldestDownloadsAuto') ?? false;

    // Data Saver
    _dataSaverMode = prefs.getBool('dataSaverMode') ?? false;
    _reducePosterQuality = prefs.getBool('reducePosterQuality') ?? false;
    _disableAutoplayTrailers = prefs.getBool('disableAutoplayTrailers') ?? false;
    _limitStreamingQuality = prefs.getBool('limitStreamingQuality') ?? false;
    _disableBackgroundRefresh = prefs.getBool('disableBackgroundRefresh') ?? false;
    _loadPostersOnlyWhenVisible = prefs.getBool('loadPostersOnlyWhenVisible') ?? true;

    // Language
    _appLanguage = prefs.getString('appLanguage') ?? 'English';
    _subtitleLanguage = prefs.getString('subtitleLanguage') ?? 'Auto detect';
    _audioLanguagePreference = prefs.getString('audioLanguagePreference') ?? 'Original';

    // Privacy
    _pauseWatchHistory = prefs.getBool('pauseWatchHistory') ?? false;
    _twoFactorAuth = prefs.getBool('twoFactorAuth') ?? false;
    _deviceLoginAlerts = prefs.getBool('deviceLoginAlerts') ?? true;

    // Preferences
    _favoriteGenres = prefs.getStringList('favoriteGenres') ?? [];
    _hideAdultContent = prefs.getBool('hideAdultContent') ?? false;
    _hideHorrorMovies = prefs.getBool('hideHorrorMovies') ?? false;
    _hideSpoilers = prefs.getBool('hideSpoilers') ?? true;
    _personalRecommendations = prefs.getBool('personalRecommendations') ?? true;

    // Developer
    _isDeveloperModeEnabled = prefs.getBool('isDeveloperModeEnabled') ?? false;
    _enableDebugLogs = prefs.getBool('enableDebugLogs') ?? false;
    _simulateSlowNetwork = prefs.getBool('simulateSlowNetwork') ?? false;

    notifyListeners();
  }

  // Setters with persistence
  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  // Setters
  void setThemeMode(ThemeMode mode) { _themeMode = mode; _saveString('themeMode', _themeModeToString(mode)); notifyListeners(); }
  void setAmoledMode(bool value) { _amoledMode = value; _saveBool('amoledMode', value); notifyListeners(); }
  void setDynamicColor(bool value) { _dynamicColor = value; _saveBool('dynamicColor', value); notifyListeners(); }
  void setAccentColor(Color color) { _accentColor = color; _saveInt('accentColor', color.value); notifyListeners(); }
  void setPosterSize(String size) { _posterSize = size; _saveString('posterSize', size); notifyListeners(); }
  void setPosterStyle(String style) { _posterStyle = style; _saveString('posterStyle', style); notifyListeners(); }
  void setUIAnimations(bool value) { _uiAnimations = value; _saveBool('uiAnimations', value); notifyListeners(); }
  void setReduceMotion(bool value) { _reduceMotion = value; _saveBool('reduceMotion', value); notifyListeners(); }

  void setNewMovieAlerts(bool value) { _newMovieAlerts = value; _saveBool('newMovieAlerts', value); notifyListeners(); }
  void setTrailerAlerts(bool value) { _trailerAlerts = value; _saveBool('trailerAlerts', value); notifyListeners(); }
  void setComingSoonReminders(bool value) { _comingSoonReminders = value; _saveBool('comingSoonReminders', value); notifyListeners(); }
  void setNewEpisodeAlerts(bool value) { _newEpisodeAlerts = value; _saveBool('newEpisodeAlerts', value); notifyListeners(); }
  void setAppUpdateNotifications(bool value) { _appUpdateNotifications = value; _saveBool('appUpdateNotifications', value); notifyListeners(); }
  void setNotifyOnSavedReleased(bool value) { _notifyOnSavedReleased = value; _saveBool('notifyOnSavedReleased', value); notifyListeners(); }
  void setNotifyOnSeriesNewEpisode(bool value) { _notifyOnSeriesNewEpisode = value; _saveBool('notifyOnSeriesNewEpisode', value); notifyListeners(); }
  void setEnableNotificationSound(bool value) { _enableNotificationSound = value; _saveBool('enableNotificationSound', value); notifyListeners(); }
  void setEnableNotificationVibration(bool value) { _enableNotificationVibration = value; _saveBool('enableNotificationVibration', value); notifyListeners(); }
  void setNotificationPriority(String priority) { _notificationPriority = priority; _saveString('notificationPriority', priority); notifyListeners(); }
  void setQuietMode(bool value) { _quietMode = value; _saveBool('quietMode', value); notifyListeners(); }
  void setQuietModeStart(TimeOfDay time) { _quietModeStart = time; _saveString('quietModeStart', '${time.hour}:${time.minute}'); notifyListeners(); }
  void setQuietModeEnd(TimeOfDay time) { _quietModeEnd = time; _saveString('quietModeEnd', '${time.hour}:${time.minute}'); notifyListeners(); }

  void setDefaultVideoQuality(String quality) { _defaultVideoQuality = quality; _saveString('defaultVideoQuality', quality); notifyListeners(); }
  void setPreferWifiStreaming(bool value) { _preferWifiStreaming = value; _saveBool('preferWifiStreaming', value); notifyListeners(); }
  void setAllowMobileDataStreaming(bool value) { _allowMobileDataStreaming = value; _saveBool('allowMobileDataStreaming', value); notifyListeners(); }
  void setDoubleTapSeek(bool value) { _doubleTapSeek = value; _saveBool('doubleTapSeek', value); notifyListeners(); }
  void setSubtitlesByDefault(bool value) { _subtitlesByDefault = value; _saveBool('subtitlesByDefault', value); notifyListeners(); }
  void setAutoplayNextEpisode(bool value) { _autoplayNextEpisode = value; _saveBool('autoplayNextEpisode', value); notifyListeners(); }
  void setSkipIntroAuto(bool value) { _skipIntroAuto = value; _saveBool('skipIntroAuto', value); notifyListeners(); }
  void setSkipCreditsAuto(bool value) { _skipCreditsAuto = value; _saveBool('skipCreditsAuto', value); notifyListeners(); }

  void setDownloadQuality(String quality) { _downloadQuality = quality; _saveString('downloadQuality', quality); notifyListeners(); }
  void setStorageLocation(String location) { _storageLocation = location; _saveString('storageLocation', location); notifyListeners(); }
  void setDownloadOnlyOnWifi(bool value) { _downloadOnlyOnWifi = value; _saveBool('downloadOnlyOnWifi', value); notifyListeners(); }
  void setAllowMobileDataDownloads(bool value) { _allowMobileDataDownloads = value; _saveBool('allowMobileDataDownloads', value); notifyListeners(); }
  void setSmartDownload(bool value) { _smartDownload = value; _saveBool('smartDownload', value); notifyListeners(); }
  void setDeleteWatchedDownloads(bool value) { _deleteWatchedDownloads = value; _saveBool('deleteWatchedDownloads', value); notifyListeners(); }
  void setDeleteOldestDownloadsAuto(bool value) { _deleteOldestDownloadsAuto = value; _saveBool('deleteOldestDownloadsAuto', value); notifyListeners(); }

  void setDataSaverMode(bool value) { _dataSaverMode = value; _saveBool('dataSaverMode', value); notifyListeners(); }
  void setReducePosterQuality(bool value) { _reducePosterQuality = value; _saveBool('reducePosterQuality', value); notifyListeners(); }
  void setDisableAutoplayTrailers(bool value) { _disableAutoplayTrailers = value; _saveBool('disableAutoplayTrailers', value); notifyListeners(); }
  void setLimitStreamingQuality(bool value) { _limitStreamingQuality = value; _saveBool('limitStreamingQuality', value); notifyListeners(); }
  void setDisableBackgroundRefresh(bool value) { _disableBackgroundRefresh = value; _saveBool('disableBackgroundRefresh', value); notifyListeners(); }
  void setLoadPostersOnlyWhenVisible(bool value) { _loadPostersOnlyWhenVisible = value; _saveBool('loadPostersOnlyWhenVisible', value); notifyListeners(); }

  void setAppLanguage(String lang) { _appLanguage = lang; _saveString('appLanguage', lang); notifyListeners(); }
  void setSubtitleLanguage(String lang) { _subtitleLanguage = lang; _saveString('subtitleLanguage', lang); notifyListeners(); }
  void setAudioLanguagePreference(String lang) { _audioLanguagePreference = lang; _saveString('audioLanguagePreference', lang); notifyListeners(); }

  void setPauseWatchHistory(bool value) { _pauseWatchHistory = value; _saveBool('pauseWatchHistory', value); notifyListeners(); }
  void setTwoFactorAuth(bool value) { _twoFactorAuth = value; _saveBool('twoFactorAuth', value); notifyListeners(); }
  void setDeviceLoginAlerts(bool value) { _deviceLoginAlerts = value; _saveBool('deviceLoginAlerts', value); notifyListeners(); }

  void setFavoriteGenres(List<String> genres) { _favoriteGenres = genres; _saveStringList('favoriteGenres', genres); notifyListeners(); }
  void setHideAdultContent(bool value) { _hideAdultContent = value; _saveBool('hideAdultContent', value); notifyListeners(); }
  void setHideHorrorMovies(bool value) { _hideHorrorMovies = value; _saveBool('hideHorrorMovies', value); notifyListeners(); }
  void setHideSpoilers(bool value) { _hideSpoilers = value; _saveBool('hideSpoilers', value); notifyListeners(); }
  void setPersonalRecommendations(bool value) { _personalRecommendations = value; _saveBool('personalRecommendations', value); notifyListeners(); }

  void setDeveloperMode(bool value) { _isDeveloperModeEnabled = value; _saveBool('isDeveloperModeEnabled', value); notifyListeners(); }
  void setEnableDebugLogs(bool value) { _enableDebugLogs = value; _saveBool('enableDebugLogs', value); notifyListeners(); }
  void setSimulateSlowNetwork(bool value) { _simulateSlowNetwork = value; _saveBool('simulateSlowNetwork', value); notifyListeners(); }

  // Helpers
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

  TimeOfDay _parseTimeOfDay(String? timeStr, TimeOfDay defaultValue) {
    if (timeStr == null) return defaultValue;
    final parts = timeStr.split(':');
    if (parts.length != 2) return defaultValue;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
