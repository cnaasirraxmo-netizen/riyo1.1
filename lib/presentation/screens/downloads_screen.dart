import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riyo/presentation/providers/download_provider.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/presentation/widgets/state_widgets.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('MY DOWNLOADS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/download-settings')),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(downloadState),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (downloadState.downloadingMovies.isNotEmpty) ...[
                  ...downloadState.downloadingMovies.map((movie) => _buildDownloadingCard(movie, downloadNotifier)),
                ],
                if (downloadState.downloadedMovies.isNotEmpty) ...[
                  ...downloadState.downloadedMovies.map((movie) => _buildDownloadedCard(movie, downloadNotifier)),
                ],
                if (downloadState.downloadingMovies.isEmpty && downloadState.downloadedMovies.isEmpty)
                  NoDownloadsState(
                    onBrowse: () => context.go('/home'),
                    onHowTo: () {},
                  ),
              ],
            ),
          ),
          _buildFooter(downloadState),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(DownloadState state) {
    final totalVideos = state.downloadedMovies.length + state.downloadingMovies.length;
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Text(
        '$totalVideos videos | Real-time Download Management',
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }

  Widget _buildDownloadingCard(Movie movie, DownloadNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: movie.posterPath.startsWith('http') ? movie.posterPath : 'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                  width: 100,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: movie.downloadProgress,
            backgroundColor: Colors.white10,
            color: Colors.deepPurpleAccent,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => notifier.cancelDownload(movie.id), child: const Text('CANCEL', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedCard(Movie movie, DownloadNotifier notifier) {
    return InkWell(
      onTap: () {
        final id = movie.backendId ?? movie.id.toString();
        context.push('/movie/$id/play');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                 imageUrl: movie.posterPath.startsWith('http') ? movie.posterPath : 'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                width: 120,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(movie.fileSize, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => notifier.deleteDownload(movie.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(DownloadState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Auto Downloads: ${state.autoDownloadEpisodes ? "ON" : "OFF"}', style: const TextStyle(color: Colors.grey)),
            TextButton(onPressed: () => context.push('/settings'), child: const Text('MANAGE')),
          ],
        ),
      ),
    );
  }
}
