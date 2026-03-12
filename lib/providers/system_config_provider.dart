import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riyo/core/constants.dart';

class SystemConfig {
  final bool downloadsEnabled;
  final bool castingEnabled;
  final bool notificationsOn;
  final bool trailerAutoplay;
  final bool commentsEnabled;
  final bool sportsEnabled;
  final bool kidsEnabled;

  SystemConfig({
    required this.downloadsEnabled,
    required this.castingEnabled,
    required this.notificationsOn,
    required this.trailerAutoplay,
    required this.commentsEnabled,
    required this.sportsEnabled,
    required this.kidsEnabled,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      downloadsEnabled: json['downloadsEnabled'] ?? true,
      castingEnabled: json['castingEnabled'] ?? true,
      notificationsOn: json['notificationsOn'] ?? true,
      trailerAutoplay: json['trailerAutoplay'] ?? true,
      commentsEnabled: json['commentsEnabled'] ?? true,
      sportsEnabled: json['sportsEnabled'] ?? true,
      kidsEnabled: json['kidsEnabled'] ?? true,
    );
  }

  factory SystemConfig.defaultConfig() {
    return SystemConfig(
      downloadsEnabled: true,
      castingEnabled: true,
      notificationsOn: true,
      trailerAutoplay: true,
      commentsEnabled: true,
      sportsEnabled: true,
      kidsEnabled: true,
    );
  }
}

class SystemConfigProvider with ChangeNotifier {
  SystemConfig _config = SystemConfig.defaultConfig();
  bool _isLoading = true;

  SystemConfig get config => _config;
  bool get isLoading => _isLoading;

  SystemConfigProvider() {
    fetchConfig();
  }

  Future<void> fetchConfig() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('${Constants.apiBaseUrl}/system-config'));
      if (response.statusCode == 200) {
        _config = SystemConfig.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching system config: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
