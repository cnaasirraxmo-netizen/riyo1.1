import 'package:flutter/material.dart';

class RiyoStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome_message': 'Welcome to RIYO',
      'login_button': 'Sign In',
      'logout_button': 'Sign Out',
      'error_network': 'Network connection lost. Please check your internet.',
      'profile_title': 'My Profile',
      'settings': 'App Settings',
      'save_button': 'Save Changes',
      'cancel_button': 'Cancel',
      'notifications': 'Notifications',
      'language_select': 'Select Language',
      'home': 'Home',
      'categories': 'Categories',
      'downloads': 'Downloads',
      'search': 'Search',
      'my_list': 'My List',
      'play_now': 'Play Now',
      'watch_trailer': 'Watch Trailer',
      'trending': 'Trending Now',
      'popular': 'Popular on RIYO',
      'top_rated': 'Top Rated',
      'offline_badge': 'OFFLINE',
      'available_offline': 'Available Offline',
      'continue_watching': 'Continue Watching',
      'no_movies_found': 'No movies found.',
    },
    'so': {
      'home': 'Hoyga',
      'categories': 'Qaybaha',
      'downloads': 'Downloads',
      'search': 'Baarista',
      'profile_title': 'Muuqaalka',
    },
    // Add other languages here if needed
  };

  static String get(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    if (_localizedValues.containsKey(locale) && _localizedValues[locale]!.containsKey(key)) {
      return _localizedValues[locale]![key]!;
    }
    // Fallback to English
    return _localizedValues['en']![key] ?? key;
  }
}

extension StringLocalization on String {
  String tr(BuildContext context) => RiyoStrings.get(context, this);
}
