import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Developer Options', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          SettingsToggle(
            icon: Icons.bug_report_outlined,
            title: 'Enable Debug Logs',
            value: settings.enableDebugLogs,
            onChanged: (val) => settings.setEnableDebugLogs(val),
          ),
          SettingsItem(
            icon: Icons.refresh,
            title: 'Reset App Cache',
            onTap: () {},
          ),
          SettingsItem(
            icon: Icons.notification_important_outlined,
            title: 'Test Push Notification',
            onTap: () {},
          ),
          SettingsToggle(
            icon: Icons.speed,
            title: 'Simulate Slow Network',
            value: settings.simulateSlowNetwork,
            onChanged: (val) => settings.setSimulateSlowNetwork(val),
          ),
          const Divider(color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => settings.setDeveloperMode(false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Disable Developer Mode', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
