import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance', style: AppTypography.titleLarge),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Theme Mode'),
          _buildRadioTile(context, 'Use Device Theme', ThemeMode.system, settings.themeMode, (val) => settings.setThemeMode(val!)),
          _buildRadioTile(context, 'Dark Mode', ThemeMode.dark, settings.themeMode, (val) => settings.setThemeMode(val!)),
          _buildRadioTile(context, 'Light Mode', ThemeMode.light, settings.themeMode, (val) => settings.setThemeMode(val!)),

          const SettingsHeader(title: 'Display Settings'),
          SettingsToggle(
            icon: Icons.brightness_2_outlined,
            title: 'AMOLED Dark Mode',
            subtitle: 'Pure black background for OLED screens',
            value: settings.amoledMode,
            onChanged: (val) => settings.setAmoledMode(val),
          ),
          SettingsToggle(
            icon: Icons.color_lens_outlined,
            title: 'Dynamic Color',
            subtitle: 'Use system accent color (Material You)',
            value: settings.dynamicColor,
            onChanged: (val) => settings.setDynamicColor(val),
          ),

          const SettingsHeader(title: 'Content Style'),
          SettingsItem(
            icon: Icons.photo_size_select_large_outlined,
            title: 'Poster Size',
            subtitle: settings.posterSize,
            onTap: () => _showPosterSizeDialog(context, settings),
          ),
          SettingsItem(
            icon: Icons.style_outlined,
            title: 'Poster Style',
            subtitle: settings.posterStyle,
            onTap: () => _showPosterStyleDialog(context, settings),
          ),

          const SettingsHeader(title: 'Accessibility'),
          SettingsToggle(
            icon: Icons.animation,
            title: 'Enable UI Animations',
            value: settings.uiAnimations,
            onChanged: (val) => settings.setUIAnimations(val),
          ),
          SettingsToggle(
            icon: Icons.motion_photos_off_outlined,
            title: 'Reduce Motion',
            value: settings.reduceMotion,
            onChanged: (val) => settings.setReduceMotion(val),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRadioTile<T>(BuildContext context, String title, T value, T groupValue, ValueChanged<T?> onChanged) {
    return RadioListTile<T>(
      title: Text(title, style: AppTypography.titleMedium),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showPosterSizeDialog(BuildContext context, SettingsProvider settings) {
    _showSelectionDialog(context, 'Poster Size', ['Small', 'Medium', 'Large'], settings.posterSize, (val) => settings.setPosterSize(val));
  }

  void _showPosterStyleDialog(BuildContext context, SettingsProvider settings) {
    _showSelectionDialog(context, 'Poster Style', ['Rounded', 'Sharp', 'Cinematic'], settings.posterStyle, (val) => settings.setPosterStyle(val));
  }

  void _showSelectionDialog(BuildContext context, String title, List<String> options, String current, ValueChanged<String> onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => RadioListTile<String>(
            title: Text(opt, style: AppTypography.bodyLarge),
            value: opt,
            groupValue: current,
            onChanged: (val) {
              onSelected(val!);
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          )).toList(),
        ),
      ),
    );
  }
}
