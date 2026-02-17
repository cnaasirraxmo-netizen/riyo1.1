import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riyobox/core/constants.dart';

class PlaybackProvider with ChangeNotifier {
  final Map<String, Duration> _progress = {};
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Duration getProgress(String movieId) => _progress[movieId] ?? Duration.zero;

  void updateProgress(String movieId, Duration position, Duration duration) {
    _progress[movieId] = position;
    _syncWithBackend(movieId, position, duration);
    notifyListeners();
  }

  void resetProgress(String movieId) {
    _progress[movieId] = Duration.zero;
    notifyListeners();
  }

  Future<void> _syncWithBackend(String movieId, Duration position, Duration duration) async {
    if (_token == null) return;
    try {
      await http.post(
        Uri.parse('${Constants.apiBaseUrl}/users/history'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'movieId': movieId,
          'progress': position.inSeconds,
          'duration': duration.inSeconds,
        }),
      );
    } catch (e) {
      print('Error syncing playback progress: $e');
    }
  }

  void loadFromProfile(List<dynamic>? history) {
    if (history == null) return;
    for (var item in history) {
      final movieId = item['movie'] is Map ? item['movie']['_id'] : item['movie'];
      if (movieId != null) {
        _progress[movieId.toString()] = Duration(seconds: item['progress'] ?? 0);
      }
    }
    notifyListeners();
  }
}
