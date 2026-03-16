import 'package:flutter/material.dart';
import 'package:riyo/services/local_cache_service.dart';

class PlaybackProvider with ChangeNotifier {
  final Map<String, Duration> _progress = {};
  final LocalCacheService _cacheService = LocalCacheService();

  PlaybackProvider() {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = _cacheService.getAllProgress();
    cached.forEach((key, value) {
      _progress[key] = Duration(milliseconds: value);
    });
    notifyListeners();
  }

  Map<String, Duration> get allProgress => Map.unmodifiable(_progress);

  Duration getProgress(String movieId) => _progress[movieId] ?? Duration.zero;

  void updateProgress(String movieId, Duration position) {
    _progress[movieId] = position;
    _cacheService.saveProgress(movieId, position.inMilliseconds);
    notifyListeners();
  }

  void resetProgress(String movieId) {
    _progress[movieId] = Duration.zero;
    _cacheService.saveProgress(movieId, 0);
    notifyListeners();
  }
}
