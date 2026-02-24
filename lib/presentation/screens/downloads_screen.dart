import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riyobox/providers/download_provider.dart';
import 'package:riyobox/models/movie.dart';
import 'package:riyobox/presentation/widgets/state_widgets.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('MY DOWNLOADS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'settings') {
                context.push('/download-settings');
              } else if (value == 'help') {
                // Show help dialog
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Download Settings'),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Text('Help'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(downloadProvider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (downloadProvider.downloadingMovies.isNotEmpty) ...[
                  ...downloadProvider.downloadingMovies.map((movie) => _buildDownloadingCard(movie, downloadProvider)),
                ],
                if (downloadProvider.downloadedMovies.isNotEmpty) ...[
                  ...downloadProvider.downloadedMovies.map((movie) => _buildDownloadedCard(movie, downloadProvider)),
                ],
                if (downloadProvider.downloadingMovies.isEmpty && downloadProvider.downloadedMovies.isEmpty)
                  NoDownloadsState(
                    onBrowse: () => context.go('/home'),
                    onHowTo: () {},
                  ),
              ],
            ),
          ),
          _buildFooter(downloadProvider),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(DownloadProvider provider) {
    final totalVideos = provider.downloadedMovies.length + provider.downloadingMovies.length;
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Text(
        '$totalVideos videos | Real-time Download Management',
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }

  Widget _buildDownloadingCard(Movie movie, DownloadProvider provider) {
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
                  placeholder: (context, url) => Container(width: 100, height: 60, color: const Color(0xFF262626)),
                  errorWidget: (context, url, error) => Container(width: 100, height: 60, color: const Color(0xFF262626), child: const Icon(Icons.movie, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(movie.isTvShow ? 'TV Series' : 'Movie', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: movie.downloadProgress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(movie.downloadProgress * 100).toInt()}% Downloading...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Row(
                children: [
                  TextButton(onPressed: () {}, child: const Text('PAUSE', style: TextStyle(color: Colors.white, fontSize: 12))),
                  TextButton(onPressed: () => provider.cancelDownload(movie.id), child: const Text('CANCEL', style: TextStyle(color: Colors.red, fontSize: 12))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedCard(Movie movie, DownloadProvider provider) {
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
                placeholder: (context, url) => Container(width: 120, height: 70, color: const Color(0xFF262626)),
                errorWidget: (context, url, error) => Container(width: 120, height: 70, color: const Color(0xFF262626), child: const Icon(Icons.check_circle, color: Colors.green)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (movie.isTvShow) ...[
                    Text(
                      'Season ${movie.seasonNumber ?? 1} | ${movie.downloadedEpisodesCount} episodes',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ] else ...[
                    Text(
                      '${movie.releaseDate.split('-')[0]} | ${movie.runtime != null ? _formatDuration(movie.runtime!) : "N/A"}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    movie.fileSize,
                    style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (value) {
                if (value == 'delete') {
                  provider.deleteDownload(movie.id);
                } else if (value == 'save') {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to library')));
                } else if (value == 'playlist') {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to playlist')));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'save', child: Text('Save')),
                const PopupMenuItem(value: 'playlist', child: Text('Add to Playlist')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }


  Widget _buildFooter(DownloadProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.downloadingMovies.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.downloading, color: Colors.deepPurpleAccent, size: 16),
                    const SizedBox(width: 8),
                    Text('Download Queue: ${provider.downloadingMovies.length} pending', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Auto Downloads: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(provider.autoDownloadEpisodes ? 'ON' : 'OFF', style: TextStyle(color: provider.autoDownloadEpisodes ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('MANAGE', style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
