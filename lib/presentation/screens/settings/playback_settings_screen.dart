import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class PlaybackSettingsScreen extends ConsumerWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Playback', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          SettingsToggle(
            icon: Icons.wifi_outlined,
            title: 'Prefer Wi-Fi Only',
            value: true,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
