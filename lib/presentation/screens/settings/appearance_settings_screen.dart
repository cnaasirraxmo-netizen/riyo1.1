import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Appearance', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Theme Mode'),
          _buildRadioTile(context, 'Use Device Theme', ThemeMode.system, settingsState.themeMode, (val) => settingsNotifier.setThemeMode(val!)),
          _buildRadioTile(context, 'Dark Mode', ThemeMode.dark, settingsState.themeMode, (val) => settingsNotifier.setThemeMode(val!)),
          _buildRadioTile(context, 'Light Mode', ThemeMode.light, settingsState.themeMode, (val) => settingsNotifier.setThemeMode(val!)),

          const SettingsHeader(title: 'Display Settings'),
          SettingsToggle(
            icon: Icons.brightness_2_outlined,
            title: 'AMOLED Dark Mode',
            subtitle: 'Pure black background for OLED screens',
            value: false, // Simplified
            onChanged: (val) {},
          ),
          SettingsToggle(
            icon: Icons.color_lens_outlined,
            title: 'Dynamic Color',
            subtitle: 'Use system accent color (Android 12+)',
            value: true, // Simplified
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile<T>(BuildContext context, String title, T value, T groupValue, ValueChanged<T?> onChanged) {
    return RadioListTile<T>(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
}
