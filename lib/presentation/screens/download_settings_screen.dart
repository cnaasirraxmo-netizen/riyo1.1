import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/download_provider.dart';

class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('DOWNLOAD SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.white),
            title: const Text('Clear All Downloads', style: TextStyle(color: Colors.redAccent)),
            onTap: () => downloadNotifier.clearAllDownloads(),
          ),
          ...downloadState.downloadedMovies.map((movie) => ListTile(
            title: Text(movie.title, style: const TextStyle(color: Colors.white)),
            trailing: Text(movie.fileSize, style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }
}
