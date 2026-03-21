import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';
import 'package:http/http.dart' as http;
import 'package:riyo/core/constants.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'User', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: Text('Premium Member', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const SettingsHeader(title: 'Account Settings'),
          SettingsItem(icon: Icons.edit_outlined, title: 'Edit Profile', onTap: () => context.push('/settings/account/edit-profile')),
          SettingsItem(icon: Icons.lock_outline, title: 'Change Password', onTap: () => context.push('/settings/account/change-password')),
          SettingsItem(icon: Icons.email_outlined, title: 'Change Email', onTap: () {}),
          SettingsItem(icon: Icons.card_membership, title: 'Manage Subscription', onTap: () {}),

          const SettingsHeader(title: 'History & Lists'),
          SettingsItem(icon: Icons.history, title: 'Watch History', onTap: () => context.push('/my-riyo')),
          SettingsItem(icon: Icons.playlist_play, title: 'Watchlist', onTap: () => context.push('/category')),

          const SettingsHeader(title: 'Devices'),
          SettingsItem(icon: Icons.devices, title: 'Connected Devices', onTap: () {}),
          SettingsItem(icon: Icons.logout_outlined, title: 'Logout from all devices', onTap: () => _showLogoutAllDialog(context, auth)),

          const SettingsHeader(title: 'Danger Zone'),
          SettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => auth.logout(),
          ),
          SettingsItem(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            onTap: () => _showDeleteAccountDialog(context, auth),
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout from all devices?'),
        content: const Text('You will remain logged in on this device, but all other active sessions will be terminated.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              try {
                await http.post(
                  Uri.parse('${Constants.apiBaseUrl}/users/logout-all'),
                  headers: {'Authorization': 'Bearer ${auth.token}'},
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out from all other devices')));
                }
              } catch (e) {}
            },
            child: const Text('LOGOUT ALL'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is permanent and will delete all your profile data, history, and watchlist.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              try {
                await auth.deleteAccount();
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/login');
                }
              } catch (e) {}
            },
            child: const Text('DELETE PERMANENTLY', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
