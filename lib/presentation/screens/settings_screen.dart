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
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('SETTINGS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('APPEARANCE'),
          _buildAppearanceSection(context, settings),
          _buildDivider(),
          _buildSectionHeader('NETWORK'),
          SwitchListTile(
            secondary: const Icon(Icons.signal_wifi_off_outlined, color: Colors.white),
            title: const Text('Offline Mode', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Simulate no internet connection', style: TextStyle(color: Colors.grey)),
            value: settings.isOffline,
            onChanged: (bool value) => settings.setOfflineMode(value),
            activeThumbColor: Colors.redAccent,
          ),
          _buildDivider(),
          _buildSectionHeader('ACCOUNT & NOTIFICATIONS'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: Colors.white),
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Receive alerts for new movies', style: TextStyle(color: Colors.grey)),
            value: settings.notificationsEnabled,
            onChanged: (bool value) => settings.toggleNotifications(value),
            activeThumbColor: Colors.deepPurpleAccent,
          ),
          _buildDivider(),
          _buildSectionHeader('DOWNLOAD SETTINGS'),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined, color: Colors.white),
            title: const Text('Download Management', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Manage storage and delete files', style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () => context.push('/download-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.high_quality_outlined, color: Colors.white),
            title: const Text('Video Quality for Downloads', style: TextStyle(color: Colors.white)),
            subtitle: Text(_getQualityText(downloads.quality), style: const TextStyle(color: Colors.grey)),
            onTap: () => _showDownloadQualityDialog(context, downloads),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wifi_outlined, color: Colors.white),
            title: const Text('Download Over Wi-Fi Only', style: TextStyle(color: Colors.white)),
            value: downloads.wifiOnly,
            onChanged: (val) => downloads.setWifiOnly(val),
            activeThumbColor: Colors.deepPurpleAccent,
          ),
          _buildSectionHeader('AUTO-DOWNLOAD'),
          CheckboxListTile(
            title: const Text('New episodes of series I watch', style: TextStyle(color: Colors.white, fontSize: 14)),
            value: downloads.autoDownloadEpisodes,
            onChanged: (val) => downloads.setAutoDownloadEpisodes(val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.deepPurpleAccent,
          ),
          CheckboxListTile(
            title: const Text('Recommended movies', style: TextStyle(color: Colors.white, fontSize: 14)),
            value: downloads.autoDownloadRecommendations,
            onChanged: (val) => downloads.setAutoDownloadRecommendations(val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.deepPurpleAccent,
          ),
          CheckboxListTile(
            title: const Text('Only when charging', style: TextStyle(color: Colors.white, fontSize: 14)),
            value: downloads.onlyWhenCharging,
            onChanged: (val) => downloads.setOnlyWhenCharging(val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.deepPurpleAccent,
          ),
          _buildSectionHeader('STORAGE MANAGEMENT'),
          SwitchListTile(
            secondary: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            title: const Text('Auto-delete after watching', style: TextStyle(color: Colors.white)),
            value: downloads.autoDeleteAfterWatching,
            onChanged: (val) => downloads.setAutoDeleteAfterWatching(val),
            activeThumbColor: Colors.deepPurpleAccent,
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: Colors.white),
            title: const Text('Keep for', style: TextStyle(color: Colors.white)),
            trailing: Text('${downloads.keepDays} days', style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
            onTap: () => _showKeepDaysDialog(context, downloads),
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
            leading: const Icon(Icons.language_outlined, color: Colors.white),
            title: const Text('Language', style: TextStyle(color: Colors.white)),
            subtitle: Text(settings.language, style: const TextStyle(color: Colors.grey)),
            onTap: () => _showLanguageDialog(context, settings),
          ),
          _buildDivider(),
          _buildSectionHeader('SUPPORT & POLICY'),
          ListTile(
            leading: const Icon(Icons.contact_support_outlined, color: Colors.white),
            title: const Text('Contacts', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => context.push('/contacts'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.white),
            title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => context.push('/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text('About', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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

  Widget _buildAppearanceSection(BuildContext context, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildThemeCard(
            context,
            'Device',
            Icons.phonelink_setup,
            settings.themeMode == ThemeMode.system,
            () => settings.setThemeMode(ThemeMode.system),
          ),
          _buildThemeCard(
            context,
            'Dark',
            Icons.dark_mode,
            settings.themeMode == ThemeMode.dark,
            () => settings.setThemeMode(ThemeMode.dark),
          ),
          _buildThemeCard(
            context,
            'Light',
            Icons.light_mode,
            settings.themeMode == ThemeMode.light,
            () => settings.setThemeMode(ThemeMode.light),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, String label, IconData icon, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withAlpha(40) : const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.white10,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? colorScheme.primary : Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityText(DownloadQuality quality) {
    switch (quality) {
      case DownloadQuality.low: return '480p (Smallest size)';
      case DownloadQuality.medium: return '720p (Recommended)';
      case DownloadQuality.high: return '1080p (Best quality) - Premium';
    }
  }

  void _showDownloadQualityDialog(BuildContext context, DownloadProvider downloads) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Video Quality', style: TextStyle(color: Colors.white)),
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

  void _showKeepDaysDialog(BuildContext context, DownloadProvider downloads) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Keep Downloads For', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [7, 14, 30, 90].map((days) => ListTile(
            title: Text('$days days', style: const TextStyle(color: Colors.white)),
            onTap: () {
              downloads.setKeepDays(days);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Select Language', style: TextStyle(color: Colors.white)),
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
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent) : null,
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL', style: TextStyle(color: Colors.white))),
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
