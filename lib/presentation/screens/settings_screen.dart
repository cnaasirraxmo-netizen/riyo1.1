import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.titleLarge),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Appearance'),
          SettingsItem(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme, AMOLED mode, posters',
            onTap: () => context.push('/settings/appearance'),
          ),
          const SettingsHeader(title: 'Account'),
          SettingsItem(
            icon: Icons.account_circle_outlined,
            title: 'Account',
            subtitle: 'Profile, password, subscription',
            onTap: () => context.push('/settings/account'),
          ),
          const SettingsHeader(title: 'Media & Playback'),
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
          const SettingsHeader(title: 'Regional'),
          SettingsItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'App language, subtitles, audio',
            onTap: () => context.push('/settings/language'),
          ),
          const SettingsHeader(title: 'Security'),
          SettingsItem(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Watch history, 2FA, permissions',
            onTap: () => context.push('/settings/privacy'),
          ),
          SettingsItem(
            icon: Icons.child_care_outlined,
            title: 'Parental Control',
            subtitle: 'Kids mode, PIN, restrictions',
            onTap: () => context.push('/settings/parental-control'),
          ),
          const SettingsHeader(title: 'More'),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
