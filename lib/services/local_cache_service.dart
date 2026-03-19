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

    try {
      _moviesBox = await Hive.openBox('movies_cache');
      _progressBox = await Hive.openBox('playback_progress');
      _historyBox = await Hive.openBox('watch_history');
      _isInitialized = true;
      debugPrint('LocalCacheService initialized successfully.');
    } catch (e) {
      debugPrint('CRITICAL: LocalCacheService failed to initialize: $e');
      // In a real app, we might want to notify the user or use a memory-only fallback
    }

    // Connectivity monitoring
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      _connectivityController.add(_isOnline);
      debugPrint('Connectivity changed: \$_isOnline');

      if (_isOnline) {
        syncOfflineData();
      }
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

    // Also add to watch history
    await addToHistory(movieId);
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

  // Watch History
  Future<void> addToHistory(String movieId) async {
    final List<String> history = List<String>.from(_historyBox.get('movie_ids', defaultValue: <String>[]));
    if (history.contains(movieId)) {
      history.remove(movieId);
    }
    history.insert(0, movieId);

    // Keep only last 50 items
    if (history.length > 50) {
      history.removeLast();
    }

    await _historyBox.put('movie_ids', history);
  }

  List<String> getHistory() {
    return List<String>.from(_historyBox.get('movie_ids', defaultValue: <String>[]));
  }

  // Synchronization Logic
  Future<void> syncOfflineData() async {
    if (!_isOnline) return;

    debugPrint('Syncing offline data...');
    // In a real app, you would send watch progress and history to the backend here
    // Example:
    // final progress = getAllProgress();
    // await _apiService.syncWatchProgress(progress);

    debugPrint('Offline sync completed.');
  }
}
