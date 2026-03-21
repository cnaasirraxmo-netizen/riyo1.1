import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  static Future<void> logButtonClick(String buttonName) async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button_id': buttonName,
      },
    );
  }

  static Future<void> logVideoStart(String title, String? id) async {
    await _analytics.logEvent(
      name: 'video_start',
      parameters: {
        'video_title': title,
        'video_id': id ?? 'unknown',
      },
    );
  }

  static Future<void> logUserLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logUserSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  static Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }
}
