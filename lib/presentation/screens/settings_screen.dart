import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/settings_provider.dart' as fr;
import 'package:riyo/presentation/providers/auth_provider.dart' as fr;
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          SettingsItem(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme, AMOLED mode, posters',
            onTap: () => context.push('/settings/appearance'),
          ),
          SettingsItem(
            icon: Icons.account_circle_outlined,
            title: 'Account',
            subtitle: 'Profile, password, subscription',
            onTap: () => context.push('/settings/account'),
          ),
          SettingsItem(
            icon: Icons.notifications_none_outlined,
            title: 'Notifications',
            subtitle: 'New movies, alerts, quiet mode',
            onTap: () => context.push('/settings/notifications'),
          ),
          SettingsItem(
            icon: Icons.play_circle_outline,
            title: 'Playback',
            subtitle: 'Quality, autoplay, skip intro',
            onTap: () => context.push('/settings/playback'),
          ),
          SettingsItem(
            icon: Icons.download_for_offline_outlined,
            title: 'Downloads',
            subtitle: 'Smart downloads, quality, storage',
            onTap: () => context.push('/settings/downloads'),
          ),
        ],
      ),
    );
  }
}
