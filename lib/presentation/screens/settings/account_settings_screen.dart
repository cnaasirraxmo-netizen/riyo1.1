import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Account', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple),
                  ),
                  child: const Text('Premium Member', style: TextStyle(color: Colors.deepPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const SettingsHeader(title: 'Account Settings'),
          SettingsItem(icon: Icons.edit_outlined, title: 'Edit Profile', onTap: () {}),
          SettingsItem(icon: Icons.lock_outline, title: 'Change Password', onTap: () {}),
          SettingsItem(icon: Icons.email_outlined, title: 'Change Email', onTap: () {}),
          SettingsItem(icon: Icons.card_membership, title: 'Manage Subscription', onTap: () {}),

          const SettingsHeader(title: 'History & Lists'),
          SettingsItem(icon: Icons.history, title: 'Watch History', onTap: () {}),
          SettingsItem(icon: Icons.playlist_play, title: 'Watchlist', onTap: () {}),

          const SettingsHeader(title: 'Devices'),
          SettingsItem(icon: Icons.devices, title: 'Connected Devices', onTap: () {}),
          SettingsItem(icon: Icons.logout_outlined, title: 'Logout from all devices', onTap: () {}),

          const SettingsHeader(title: 'Danger Zone'),
          SettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => auth.logout(),
          ),
          SettingsItem(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            onTap: () {},
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
