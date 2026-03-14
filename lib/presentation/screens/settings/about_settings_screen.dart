import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riyo/services/update_service.dart';

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  int _tapCount = 0;
  String _version = '...';
  String _buildNumber = '...';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  void _handleVersionTap(BuildContext context, SettingsProvider settings) {
    if (settings.isDeveloperModeEnabled) return;

    _tapCount++;
    if (_tapCount == 7) {
      settings.setDeveloperMode(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Developer options enabled')),
      );
    } else if (_tapCount > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are ${7 - _tapCount} steps away from being a developer'), duration: const Duration(milliseconds: 500)),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isChecking = true);
    final update = await UpdateService.checkForUpdates();
    setState(() => _isChecking = false);

    if (!mounted) return;

    if (update != null) {
      _showUpdateDialog(update);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are using the latest version')),
      );
    }
  }

  void _showUpdateDialog(Map<String, dynamic> update) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Available: v${update['version']}'),
        content: Text(update['description'] ?? 'A new version of RIYO is available. Would you like to download it now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('LATER')),
          ElevatedButton(
            onPressed: () {
              UpdateService.downloadUpdate(update['download_url']);
              Navigator.pop(context);
            },
            child: const Text('DOWNLOAD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.movie, size: 50, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('RIYO Streaming', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SettingsItem(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: 'v$_version',
            onTap: () => _handleVersionTap(context, settings),
            trailing: const SizedBox.shrink(),
          ),
          SettingsItem(icon: Icons.numbers, title: 'Build Number', subtitle: _buildNumber, trailing: const SizedBox.shrink()),
          const SettingsItem(icon: Icons.person_outline, title: 'Developer', subtitle: 'RIYO Team', trailing: SizedBox.shrink()),
          const SettingsItem(icon: Icons.assignment_outlined, title: 'License', subtitle: 'MIT License', trailing: SizedBox.shrink()),

          if (settings.isDeveloperModeEnabled)
            SettingsItem(
              icon: Icons.developer_mode,
              title: 'Developer Options',
              subtitle: 'Advanced debug settings',
              onTap: () => context.push('/settings/developer'),
            ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkForUpdates,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_isChecking ? 'Checking...' : 'Check for Updates', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Text('v$_version is currently installed', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
