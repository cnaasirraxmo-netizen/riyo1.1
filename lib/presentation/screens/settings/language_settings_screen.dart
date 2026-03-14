import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('language_select'.tr()),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Application'),
          SettingsItem(
            icon: Icons.language_outlined,
            title: 'App Language',
            subtitle: settings.appLanguage,
            onTap: () => _showLanguageDialog(context, settings),
          ),

          const SettingsHeader(title: 'Content'),
          SettingsItem(
            icon: Icons.subtitles_outlined,
            title: 'Subtitle Language',
            subtitle: settings.subtitleLanguage,
            onTap: () => _showDialog(context, 'Subtitle Language', ['Auto detect', 'English', 'Arabic', 'Somali'], settings.subtitleLanguage, (val) => settings.setSubtitleLanguage(val)),
          ),
          SettingsItem(
            icon: Icons.audiotrack_outlined,
            title: 'Audio Language Preference',
            subtitle: settings.audioLanguagePreference,
            onTap: () => _showDialog(context, 'Audio Language', ['Original', 'English', 'Arabic'], settings.audioLanguagePreference, (val) => settings.setAudioLanguagePreference(val)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final languages = {
      'English': const Locale('en'),
      'Somali': const Locale('so'),
      'Arabic': const Locale('ar'),
      'Spanish': const Locale('es'),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('language_select'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.keys.map((lang) => RadioListTile<String>(
            title: Text(lang),
            value: lang,
            groupValue: settings.appLanguage,
            onChanged: (val) {
              settings.setAppLanguage(val!);
              context.setLocale(languages[val]!);
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          )).toList(),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, String title, List<String> options, String current, ValueChanged<String> onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => RadioListTile<String>(
            title: Text(opt),
            value: opt,
            groupValue: current,
            onChanged: (val) {
              onSelected(val!);
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          )).toList(),
        ),
      ),
    );
  }
}
