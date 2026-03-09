import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class DataSaverSettingsScreen extends StatelessWidget {
  const DataSaverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Data Saver', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data Saver mode automatically adjusts settings to reduce data usage while streaming.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SettingsToggle(
            icon: Icons.data_saver_on_outlined,
            title: 'Enable Data Saver Mode',
            value: settings.dataSaverMode,
            onChanged: (val) => settings.setDataSaverMode(val),
          ),
          const Divider(color: Colors.white10),
          const SettingsHeader(title: 'Manual Controls'),
          SettingsToggle(
            icon: Icons.image_outlined,
            title: 'Reduce Poster Quality',
            value: settings.reducePosterQuality,
            onChanged: (val) => settings.setReducePosterQuality(val),
          ),
          SettingsToggle(
            icon: Icons.play_circle_outline,
            title: 'Disable Auto-play Trailers',
            value: settings.disableAutoplayTrailers,
            onChanged: (val) => settings.setDisableAutoplayTrailers(val),
          ),
          SettingsToggle(
            icon: Icons.high_quality_outlined,
            title: 'Limit Streaming Quality',
            subtitle: 'Forces 480p on mobile data',
            value: settings.limitStreamingQuality,
            onChanged: (val) => settings.setLimitStreamingQuality(val),
          ),
          SettingsToggle(
            icon: Icons.refresh_outlined,
            title: 'Disable Background Refresh',
            value: settings.disableBackgroundRefresh,
            onChanged: (val) => settings.setDisableBackgroundRefresh(val),
          ),
        ],
      ),
    );
  }
}
