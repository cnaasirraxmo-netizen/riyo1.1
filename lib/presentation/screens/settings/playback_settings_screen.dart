import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class PlaybackSettingsScreen extends StatelessWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback Settings'),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Quality'),
          SettingsItem(
            icon: Icons.high_quality_outlined,
            title: 'Default Video Quality',
            subtitle: settings.defaultVideoQuality,
            onTap: () => _showQualityDialog(context, settings),
          ),

          const SettingsHeader(title: 'Player Defaults'),
          SettingsItem(
            icon: Icons.speed_rounded,
            title: 'Default Playback Speed',
            subtitle: '${settings.defaultPlaybackSpeed}x',
            onTap: () => _showSpeedDialog(context, settings),
          ),
          SettingsItem(
            icon: Icons.subtitles_rounded,
            title: 'Default Subtitle Language',
            subtitle: settings.subtitleLanguage,
            onTap: () => _showSubtitleLangDialog(context, settings),
          ),

          const SettingsHeader(title: 'Streaming'),
          SettingsToggle(
            icon: Icons.wifi_outlined,
            title: 'Prefer Wi-Fi Only',
            value: settings.preferWifiStreaming,
            onChanged: (val) => settings.setPreferWifiStreaming(val),
          ),
          SettingsToggle(
            icon: Icons.cell_tower_outlined,
            title: 'Allow Mobile Data',
            value: settings.allowMobileDataStreaming,
            onChanged: (val) => settings.setAllowMobileDataStreaming(val),
          ),

          const SettingsHeader(title: 'Behavior'),
          SettingsToggle(
            icon: Icons.touch_app_outlined,
            title: 'Double Tap Seek',
            subtitle: '10 seconds forward/backward',
            value: settings.doubleTapSeek,
            onChanged: (val) => settings.setDoubleTapSeek(val),
          ),
          SettingsToggle(
            icon: Icons.subtitles_outlined,
            title: 'Subtitles by Default',
            value: settings.subtitlesByDefault,
            onChanged: (val) => settings.setSubtitlesByDefault(val),
          ),
          SettingsToggle(
            icon: Icons.skip_next_outlined,
            title: 'Autoplay Next Episode',
            value: settings.autoplayNextEpisode,
            onChanged: (val) => settings.setAutoplayNextEpisode(val),
          ),
          SettingsToggle(
            icon: Icons.fast_forward_outlined,
            title: 'Skip Intro Automatically',
            value: settings.skipIntroAuto,
            onChanged: (val) => settings.setSkipIntroAuto(val),
          ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context, SettingsProvider settings) {
    _showRadioDialog(context, 'Video Quality', ['Auto', '1080p', '720p', '480p', '360p'], settings.defaultVideoQuality, (val) {
      settings.setDefaultVideoQuality(val);
    });
  }

  void _showSpeedDialog(BuildContext context, SettingsProvider settings) {
    _showRadioDialog(context, 'Playback Speed', ['0.5', '1.0', '1.5', '2.0'], settings.defaultPlaybackSpeed.toString(), (val) {
      settings.setDefaultPlaybackSpeed(double.parse(val));
    });
  }

  void _showSubtitleLangDialog(BuildContext context, SettingsProvider settings) {
     _showRadioDialog(context, 'Subtitle Language', ['Auto detect', 'English', 'Spanish', 'French', 'Hindi'], settings.subtitleLanguage, (val) {
      settings.setSubtitleLanguage(val);
    });
  }

  void _showRadioDialog(BuildContext context, String title, List<String> options, String currentValue, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => RadioListTile<String>(
            title: Text(opt),
            value: opt,
            groupValue: currentValue,
            onChanged: (val) {
              onSelect(val!);
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          )).toList(),
        ),
      ),
    );
  }
}
