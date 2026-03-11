import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/settings_provider.dart' as riverpod;

class SettingsProvider extends ChangeNotifier {
  final Ref ref;

  SettingsProvider(this.ref) {
    ref.listen(riverpod.settingsProvider, (previous, next) {
      notifyListeners();
    });
  }

  bool get isOffline => ref.read(riverpod.settingsProvider).isOffline;
  ThemeMode get themeMode => ref.read(riverpod.settingsProvider).themeMode;
  String get language => ref.read(riverpod.settingsProvider).language;
  bool get dataSaverMode => ref.read(riverpod.settingsProvider).dataSaverMode;

  void setThemeMode(ThemeMode m) => ref.read(riverpod.settingsProvider.notifier).setThemeMode(m);
  void setOfflineMode(bool v) => ref.read(riverpod.settingsProvider.notifier).setOfflineMode(v);

  // Appearance
  bool get amoledMode => false;
  bool get dynamicColor => true;
  String get posterSize => 'Medium';
  String get posterStyle => 'Rounded';
  bool get uiAnimations => true;
  bool get reduceMotion => false;

  // Notifications
  bool get newMovieAlerts => true;
  bool get trailerAlerts => true;
  bool get comingSoonReminders => true;
  bool get notifyOnSavedReleased => true;
  bool get enableNotificationSound => true;
  bool get enableNotificationVibration => true;
  bool get quietMode => false;
  TimeOfDay get quietModeStart => const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay get quietModeEnd => const TimeOfDay(hour: 7, minute: 0);

  // Playback
  String get defaultVideoQuality => 'Auto';
  bool get preferWifiStreaming => true;
  bool get allowMobileDataStreaming => true;
  bool get doubleTapSeek => true;
  bool get subtitlesByDefault => false;
  bool get autoplayNextEpisode => true;
  bool get skipIntroAuto => false;
  bool get skipCreditsAuto => false;

  // Downloads
  String get downloadQuality => 'Medium';
  String get storageLocation => 'Internal';
  bool get downloadOnlyOnWifi => true;
  bool get smartDownload => true;
  bool get deleteWatchedDownloads => false;
  bool get deleteOldestDownloadsAuto => false;

  void setAmoledMode(bool v) {}
  void setDynamicColor(bool v) {}
  void setPosterSize(String s) {}
  void setPosterStyle(String s) {}
  void setUIAnimations(bool v) {}
  void setReduceMotion(bool v) {}
  void setNewMovieAlerts(bool v) {}
  void setTrailerAlerts(bool v) {}
  void setComingSoonReminders(bool v) {}
  void setNotifyOnSavedReleased(bool v) {}
  void setEnableNotificationSound(bool v) {}
  void setEnableNotificationVibration(bool v) {}
  void setQuietMode(bool v) {}
  void setQuietModeStart(TimeOfDay t) {}
  void setQuietModeEnd(TimeOfDay t) {}
  void setDefaultVideoQuality(String q) {}
  void setPreferWifiStreaming(bool v) {}
  void setAllowMobileDataStreaming(bool v) {}
  void setDoubleTapSeek(bool v) {}
  void setSubtitlesByDefault(bool v) {}
  void setAutoplayNextEpisode(bool v) {}
  void setSkipIntroAuto(bool v) {}
  void setSkipCreditsAuto(bool v) {}
  void setDownloadQuality(String q) {}
  void setStorageLocation(String l) {}
  void setDownloadOnlyOnWifi(bool v) {}
  void setSmartDownload(bool v) {}
  void setDeleteWatchedDownloads(bool v) {}
  void setDeleteOldestDownloadsAuto(bool v) {}
  void setAppLanguage(String l) {}
  void setDataSaverMode(bool v) {}
}
