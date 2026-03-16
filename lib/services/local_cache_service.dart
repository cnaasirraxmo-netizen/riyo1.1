import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  late Box _moviesBox;
  late Box _progressBox;
  late Box _historyBox;

  bool _isInitialized = false;
  final _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    if (_isInitialized) return;

    _moviesBox = await Hive.openBox('movies_cache');
    _progressBox = await Hive.openBox('playback_progress');
    _historyBox = await Hive.openBox('watch_history');

    _isInitialized = true;

    // Connectivity monitoring
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      _connectivityController.add(_isOnline);
      debugPrint('Connectivity changed: \$_isOnline');
    });

    // Initial check
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    _connectivityController.add(_isOnline);
  }

  // Generic Cache Methods
  Future<void> cacheMovie(String id, Map<String, dynamic> movieData) async {
    await _moviesBox.put(id, movieData);
  }

  Map<String, dynamic>? getCachedMovie(String id) {
    final data = _moviesBox.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> cacheMovieList(String key, List<Map<String, dynamic>> movies) async {
    await _moviesBox.put(key, movies);
  }

  List<Map<String, dynamic>>? getCachedMovieList(String key) {
    final data = _moviesBox.get(key);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  // Playback Progress
  Future<void> saveProgress(String movieId, int positionMillis) async {
    await _progressBox.put(movieId, positionMillis);
  }

  int getProgress(String movieId) {
    return _progressBox.get(movieId, defaultValue: 0);
  }

  Map<String, int> getAllProgress() {
    final Map<String, int> progress = {};
    for (var key in _progressBox.keys) {
      progress[key.toString()] = _progressBox.get(key);
    }
    return progress;
  }
}
