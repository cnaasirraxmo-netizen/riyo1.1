import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/providers/download_provider.dart';

class DownloadSettingsScreen extends StatelessWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = Provider.of<DownloadProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('DOWNLOAD SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('STORAGE MANAGEMENT'),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text('Delete Oldest Download', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Remove the first movie you downloaded', style: TextStyle(color: Colors.grey)),
            onTap: () => _confirmDelete(context, 'oldest', () => downloads.deleteOldestDownload()),
          ),
          ListTile(
            leading: const Icon(Icons.straighten, color: Colors.white),
            title: const Text('Delete Largest Download', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Free up maximum space', style: TextStyle(color: Colors.grey)),
            onTap: () => _confirmDelete(context, 'largest', () => downloads.deleteLargestDownload()),
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.white),
            title: const Text('Clear All Downloads', style: TextStyle(color: Colors.redAccent)),
            onTap: () => _confirmDelete(context, 'all', () => downloads.clearAllDownloads()),
          ),
          _buildDivider(),
          _buildSectionHeader('MANAGE BY SIZE'),
          if (downloads.downloadedMovies.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No downloads available to manage.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...downloads.downloadedMovies.map((movie) => ListTile(
              title: Text(movie.title, style: const TextStyle(color: Colors.white)),
              trailing: Text(movie.fileSize, style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
              subtitle: Text(movie.releaseDate, style: const TextStyle(color: Colors.grey)),
            )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white10, thickness: 1, indent: 16, endIndent: 16);
  }

  void _confirmDelete(BuildContext context, String type, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text('Delete $type?', style: const TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete the $type download(s)?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $type successful')));
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
