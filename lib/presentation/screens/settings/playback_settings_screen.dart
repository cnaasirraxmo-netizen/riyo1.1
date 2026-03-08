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
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Playback', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
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

          const SettingsHeader(title: 'Player Controls'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Video Quality', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Auto', '1080p', '720p', '480p', '360p'].map((opt) => RadioListTile<String>(
            title: Text(opt, style: const TextStyle(color: Colors.white)),
            value: opt,
            groupValue: settings.defaultVideoQuality,
            onChanged: (val) {
              settings.setDefaultVideoQuality(val!);
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).primaryColor,
          )).toList(),
        ),
      ),
    );
  }
}
