import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';
import 'package:go_router/go_router.dart';

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  int _tapCount = 0;

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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('About', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.movie, size: 50, color: Colors.deepPurple),
                ),
                SizedBox(height: 16),
                Text('RIYO Streaming', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SettingsItem(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: 'v2.5.0',
            onTap: () => _handleVersionTap(context, settings),
            trailing: const SizedBox.shrink(),
          ),
          const SettingsItem(icon: Icons.numbers, title: 'Build Number', subtitle: '1024', trailing: SizedBox.shrink()),
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
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Check for Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Text('You are using the latest version', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
