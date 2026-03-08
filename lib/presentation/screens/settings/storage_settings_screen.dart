import 'package:flutter/material.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class StorageSettingsScreen extends StatelessWidget {
  const StorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Storage Management', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildStorageSummary(),
          const SizedBox(height: 20),
          const SettingsHeader(title: 'Cleanup'),
          SettingsItem(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear App Cache',
            subtitle: '124 MB',
            onTap: () {},
          ),
          SettingsItem(
            icon: Icons.image_search_outlined,
            title: 'Clear Image Cache',
            subtitle: '45 MB',
            onTap: () {},
          ),
          SettingsItem(
            icon: Icons.delete_outline,
            title: 'Clear All Downloads',
            subtitle: '2.4 GB',
            onTap: () {},
          ),

          const SettingsHeader(title: 'Downloads by Size'),
          _buildDownloadItem('Interstellar', '1.2 GB'),
          _buildDownloadItem('Inception', '850 MB'),
          _buildDownloadItem('The Dark Knight', '420 MB'),
        ],
      ),
    );
  }

  Widget _buildStorageSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device Storage', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text('84.2 GB of 128 GB used', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(String title, String size) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 60,
        color: Colors.white10,
        child: const Icon(Icons.movie_outlined, color: Colors.grey),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(size, style: const TextStyle(color: Colors.grey)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () {},
      ),
    );
  }
}
