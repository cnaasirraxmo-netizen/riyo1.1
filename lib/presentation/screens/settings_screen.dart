import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          SettingsItem(
            icon: Icons.data_usage,
            title: 'Data Saver',
            subtitle: 'Reduce image quality, limit data',
            onTap: () => context.push('/settings/data-saver'),
          ),
          SettingsItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'App language, subtitles, audio',
            onTap: () => context.push('/settings/language'),
          ),
          SettingsItem(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Watch history, 2FA, permissions',
            onTap: () => context.push('/settings/privacy'),
          ),
          SettingsItem(
            icon: Icons.tune_outlined,
            title: 'Preferences',
            subtitle: 'Favorite genres, hide content',
            onTap: () => context.push('/settings/preferences'),
          ),
          SettingsItem(
            icon: Icons.storage_outlined,
            title: 'Storage Management',
            subtitle: 'Clear cache, manage downloads',
            onTap: () => context.push('/settings/storage'),
          ),
          SettingsItem(
            icon: Icons.help_outline,
            title: 'Support & Policy',
            subtitle: 'Contact, terms, privacy policy',
            onTap: () => context.push('/settings/support'),
          ),
          SettingsItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version, license, updates',
            onTap: () => context.push('/settings/about'),
          ),
        ],
      ),
    );
  }
}
