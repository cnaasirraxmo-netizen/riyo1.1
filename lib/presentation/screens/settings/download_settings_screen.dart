import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class DownloadSettingsScreen extends StatelessWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Downloads', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Quality'),
          SettingsItem(
            icon: Icons.high_quality_outlined,
            title: 'Download Quality',
            subtitle: settings.downloadQuality,
            onTap: () => _showQualityDialog(context, settings),
          ),

          const SettingsHeader(title: 'Storage'),
          SettingsItem(
            icon: Icons.sd_card_outlined,
            title: 'Storage Location',
            subtitle: settings.storageLocation,
            onTap: () => _showStorageDialog(context, settings),
          ),

          const SettingsHeader(title: 'Behavior'),
          SettingsToggle(
            icon: Icons.wifi_outlined,
            title: 'Download on Wi-Fi only',
            value: settings.downloadOnlyOnWifi,
            onChanged: (val) => settings.setDownloadOnlyOnWifi(val),
          ),
          SettingsToggle(
            icon: Icons.autorenew_outlined,
            title: 'Smart Download',
            subtitle: 'Automatically download next episode',
            value: settings.smartDownload,
            onChanged: (val) => settings.setSmartDownload(val),
          ),

          const SettingsHeader(title: 'Auto Delete'),
          SettingsToggle(
            icon: Icons.delete_sweep_outlined,
            title: 'Delete watched downloads',
            value: settings.deleteWatchedDownloads,
            onChanged: (val) => settings.setDeleteWatchedDownloads(val),
          ),
          SettingsToggle(
            icon: Icons.history_outlined,
            title: 'Delete oldest downloads',
            subtitle: 'Automatically when storage is full',
            value: settings.deleteOldestDownloadsAuto,
            onChanged: (val) => settings.setDeleteOldestDownloadsAuto(val),
          ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context, SettingsProvider settings) {
    _showRadioDialog(context, 'Download Quality', ['High', 'Medium', 'Low'], settings.downloadQuality, (val) => settings.setDownloadQuality(val));
  }

  void _showStorageDialog(BuildContext context, SettingsProvider settings) {
    _showRadioDialog(context, 'Storage Location', ['Internal', 'SD Card'], settings.storageLocation, (val) => settings.setStorageLocation(val));
  }

  void _showRadioDialog(BuildContext context, String title, List<String> options, String current, ValueChanged<String> onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => RadioListTile<String>(
            title: Text(opt, style: const TextStyle(color: Colors.white)),
            value: opt,
            groupValue: current,
            onChanged: (val) {
              onSelected(val!);
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).primaryColor,
          )).toList(),
        ),
      ),
    );
  }
}
