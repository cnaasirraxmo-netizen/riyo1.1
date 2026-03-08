import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Watch History'),
          SettingsToggle(
            icon: Icons.pause_circle_outline,
            title: 'Pause Watch History',
            value: settings.pauseWatchHistory,
            onChanged: (val) => settings.setPauseWatchHistory(val),
          ),
          SettingsItem(
            icon: Icons.delete_outline,
            title: 'Clear Watch History',
            onTap: () => _confirmAction(context, 'Clear Watch History', 'Are you sure you want to clear your entire watch history?'),
          ),

          const SettingsHeader(title: 'Search History'),
          SettingsItem(
            icon: Icons.history,
            title: 'Clear Search History',
            onTap: () => _confirmAction(context, 'Clear Search History', 'This will remove all your previous searches.'),
          ),

          const SettingsHeader(title: 'Security'),
          SettingsToggle(
            icon: Icons.vibration, // Using vibration icon as placeholder for 2fa
            title: 'Two-factor Authentication',
            value: settings.twoFactorAuth,
            onChanged: (val) => settings.setTwoFactorAuth(val),
          ),
          SettingsToggle(
            icon: Icons.notifications_active_outlined,
            title: 'Device Login Alerts',
            value: settings.deviceLoginAlerts,
            onChanged: (val) => settings.setDeviceLoginAlerts(val),
          ),

          const SettingsHeader(title: 'Permissions'),
          SettingsItem(
            icon: Icons.settings_applications,
            title: 'Manage Permissions',
            subtitle: 'Notifications, Storage, Network',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _confirmAction(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLEAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
