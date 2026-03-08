import 'package:flutter/material.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Support & Policy', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Support'),
          SettingsItem(icon: Icons.contact_support_outlined, title: 'Contact Us', onTap: () {}),
          SettingsItem(icon: Icons.help_center_outlined, title: 'Help Center', onTap: () {}),

          const SettingsHeader(title: 'Legal'),
          SettingsItem(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
          SettingsItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
          SettingsItem(icon: Icons.gavel_outlined, title: 'Community Guidelines', onTap: () {}),
        ],
      ),
    );
  }
}
