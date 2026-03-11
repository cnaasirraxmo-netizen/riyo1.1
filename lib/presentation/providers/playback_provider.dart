import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:flutter/material.dart';
import 'package:riyo/data/cache/cache_service.dart';
import 'package:riyo/main.dart';

class PlaybackState {
  final Map<String, Duration> progress;

  PlaybackState({this.progress = const {}});

  PlaybackState copyWith({Map<String, Duration>? progress}) {
    return PlaybackState(progress: progress ?? this.progress);
  }
}

class PlaybackNotifier extends fr.Notifier<PlaybackState> {
  CacheService get _cache => ref.read(cacheServiceProvider);

  @override
  PlaybackState build() {
    _loadFromCache();
    return PlaybackState();
  }

  void _loadFromCache() {
    final activity = _cache.getAllRecentActivity();
    final progressMap = <String, Duration>{};
    for (var item in activity) {
      progressMap[item.movieId] = Duration(seconds: item.positionSeconds);
    }
    state = state.copyWith(progress: progressMap);
  }

  Duration getProgress(String movieId) => state.progress[movieId] ?? Duration.zero;

  void updateProgress(String movieId, Duration position) {
    final newProgress = Map<String, Duration>.from(state.progress);
    newProgress[movieId] = position;
    state = state.copyWith(progress: newProgress);

    // Persist to Hive
    _cache.savePlaybackProgress(movieId, position.inSeconds, 0); // 0 for duration for now
  }

  void resetProgress(String movieId) {
    final newProgress = Map<String, Duration>.from(state.progress);
    newProgress[movieId] = Duration.zero;
    state = state.copyWith(progress: newProgress);
    _cache.savePlaybackProgress(movieId, 0, 0);
  }
}

final playbackProvider = fr.NotifierProvider<PlaybackNotifier, PlaybackState>(() {
  return PlaybackNotifier();
});
