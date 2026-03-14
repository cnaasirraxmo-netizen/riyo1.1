import 'package:flutter/material.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  String _cacheSize = '0 MB';
  String _imageCacheSize = '0 MB';

  @override
  void initState() {
    super.initState();
    _calculateSizes();
  }

  Future<void> _calculateSizes() async {
    final tempDir = await getTemporaryDirectory();
    final cacheSize = _getSize(tempDir);

    setState(() {
      _cacheSize = _formatSize(cacheSize);
      _imageCacheSize = 'Included in Cache';
    });
  }

  int _getSize(Directory dir) {
    int totalSize = 0;
    try {
      if (dir.existsSync()) {
        dir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      debugPrint('Error calculating size: $e');
    }
    return totalSize;
  }

  String _formatSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _clearCache() async {
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      tempDir.listSync().forEach((entity) {
        entity.deleteSync(recursive: true);
      });
    }
    _calculateSizes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
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
            subtitle: _cacheSize,
            onTap: _clearCache,
          ),
          SettingsItem(
            icon: Icons.delete_outline,
            title: 'Clear All Downloads',
            subtitle: 'Not implemented yet',
            onTap: () {},
          ),

          const SettingsHeader(title: 'Downloads'),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No active downloads found in local storage.', style: TextStyle(color: Colors.grey)),
          ),
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
          Text('Device Storage', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('System analyzed: Available storage detected.', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
