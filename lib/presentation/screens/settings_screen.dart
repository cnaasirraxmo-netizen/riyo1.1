import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/providers/settings_provider.dart';
import 'package:riyobox/providers/download_provider.dart';
import 'package:riyobox/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final downloads = Provider.of<DownloadProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('DISPLAY'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('App Theme'),
            subtitle: Text(_getThemeText(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showThemeDialog(context, settings),
          ),
          _buildDivider(),

          _buildSectionHeader('NETWORK & DATA'),
          SwitchListTile(
            secondary: const Icon(Icons.signal_wifi_off_outlined),
            title: const Text('Offline Mode'),
            subtitle: const Text('Simulate no internet connection'),
            value: settings.isOffline,
            onChanged: (bool value) => settings.setOfflineMode(value),
            activeTrackColor: Colors.redAccent,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.data_usage),
            title: const Text('Data Saver'),
            subtitle: const Text('Lower video quality to save mobile data'),
            value: settings.isDataSaverEnabled,
            onChanged: (bool value) => settings.toggleDataSaver(value),
            activeTrackColor: Colors.deepPurpleAccent,
          ),
          _buildDivider(),

          _buildSectionHeader('PARENTAL CONTROLS'),
          SwitchListTile(
            secondary: const Icon(Icons.family_restroom),
            title: const Text('Parental Controls'),
            subtitle: const Text('Restricts adult content with PIN'),
            value: settings.parentalControlsEnabled,
            onChanged: (bool value) => settings.toggleParentalControls(value),
            activeTrackColor: Colors.deepPurpleAccent,
          ),
          _buildDivider(),

          _buildSectionHeader('ACCOUNT & NOTIFICATIONS'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Receive alerts for new movies'),
            value: settings.notificationsEnabled,
            onChanged: (bool value) => settings.toggleNotifications(value),
            activeTrackColor: Colors.deepPurpleAccent,
          ),
          _buildDivider(),

          _buildSectionHeader('DOWNLOAD SETTINGS'),
          ListTile(
            leading: const Icon(Icons.high_quality_outlined),
            title: const Text('Video Quality for Downloads'),
            subtitle: Text(_getQualityText(downloads.quality)),
            onTap: () => _showDownloadQualityDialog(context, downloads),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wifi_outlined),
            title: const Text('Download Over Wi-Fi Only'),
            value: downloads.wifiOnly,
            onChanged: (val) => downloads.setWifiOnly(val),
            activeTrackColor: Colors.deepPurpleAccent,
          ),
          _buildSectionHeader('STORAGE MANAGEMENT'),
          SwitchListTile(
            secondary: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Auto-delete after watching'),
            value: downloads.autoDeleteAfterWatching,
            onChanged: (val) => downloads.setAutoDeleteAfterWatching(val),
            activeTrackColor: Colors.deepPurpleAccent,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () => downloads.clearAllDownloads(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('CLEAR ALL DOWNLOADS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
          _buildDivider(),

          _buildSectionHeader('PREFERENCES'),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: Text(settings.language),
            onTap: () => _showLanguageDialog(context, settings),
          ),
          _buildDivider(),

          _buildSectionHeader('SUPPORT'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help Center'),
            subtitle: const Text('FAQs and Customer Support'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push('/support'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About RIYOBOX'),
            subtitle: const Text('Version, Credits, and Legal'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push('/about'),
          ),
          _buildDivider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text('RIYOBOX v2.4.0', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white10, thickness: 1, indent: 16, endIndent: 16);
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System Default';
      case ThemeMode.light: return 'Light Mode';
      case ThemeMode.dark: return 'Dark Mode';
    }
  }

  String _getQualityText(DownloadQuality quality) {
    switch (quality) {
      case DownloadQuality.low: return '480p (Smallest size)';
      case DownloadQuality.medium: return '720p (Recommended)';
      case DownloadQuality.high: return '1080p (Best quality) - Premium';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption(context, 'System Default', settings.themeMode == ThemeMode.system, () {
              settings.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            }),
            _buildRadioOption(context, 'Light Mode', settings.themeMode == ThemeMode.light, () {
              settings.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            }),
            _buildRadioOption(context, 'Dark Mode', settings.themeMode == ThemeMode.dark, () {
              settings.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showDownloadQualityDialog(BuildContext context, DownloadProvider downloads) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption(context, '480p (Smallest size)', downloads.quality == DownloadQuality.low, () {
              downloads.setQuality(DownloadQuality.low);
              Navigator.pop(context);
            }),
            _buildRadioOption(context, '720p (Recommended)', downloads.quality == DownloadQuality.medium, () {
              downloads.setQuality(DownloadQuality.medium);
              Navigator.pop(context);
            }),
            _buildRadioOption(context, '1080p (Best quality)', downloads.quality == DownloadQuality.high, () {
              downloads.setQuality(DownloadQuality.high);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Arabic', 'Somali'].map((lang) => _buildRadioOption(context, lang, settings.language == lang, () {
            settings.setLanguage(lang);
            Navigator.pop(context);
          })).toList(),
        ),
      ),
    );
  }

  Widget _buildRadioOption(BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent) : null,
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          TextButton(onPressed: () async {
            await Provider.of<AuthProvider>(context, listen: false).logout();
            if (context.mounted) {
              Navigator.pop(dialogContext);
              context.go('/login');
            }
          }, child: const Text('LOG OUT', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
