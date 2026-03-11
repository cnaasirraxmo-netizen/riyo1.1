import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Downloads', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          SettingsToggle(
            icon: Icons.wifi_outlined,
            title: 'Download on Wi-Fi only',
            value: true,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
