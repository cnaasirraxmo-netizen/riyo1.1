import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/providers/download_provider.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/presentation/widgets/state_widgets.dart';

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
      appBar: AppBar(
        title: Text('My Downloads', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/download-settings'),
          ),
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(downloadProvider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildFooter(downloadProvider),
    );
  }

  Widget _buildSummaryHeader(DownloadProvider provider) {
    final totalVideos = provider.downloadedMovies.length + provider.downloadingMovies.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        '$totalVideos videos available offline',
        style: AppTypography.labelSmall,
      ),
    );
  }

  Widget _buildDownloadingCard(Movie movie, DownloadProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.amoledSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: movie.posterPath.startsWith('http') ? movie.posterPath : 'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                  width: 80,
                  height: 45,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.withAlpha(20)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(movie.isTvShow ? 'TV Series' : 'Movie', style: AppTypography.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: movie.downloadProgress,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(movie.downloadProgress * 100).toInt()}% Downloading', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton(onPressed: () => provider.cancelDownload(movie.id), child: const Text('Cancel')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedCard(Movie movie, DownloadProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        final id = movie.backendId ?? movie.id.toString();
        context.push('/movie/$id/play');
      },
      borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.amoledSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                 imageUrl: movie.posterPath.startsWith('http') ? movie.posterPath : 'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                width: 100,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.fileSize,
                    style: AppTypography.labelSmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => provider.deleteDownload(movie.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(DownloadProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.amoledBackground : AppColors.lightBackground,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Smart Downloads', style: AppTypography.labelLarge),
                Text(provider.autoDownloadEpisodes ? 'Auto-update enabled' : 'Disabled', style: AppTypography.labelSmall),
              ],
            ),
            Switch(
              value: provider.autoDownloadEpisodes,
              onChanged: (val) {
                // Toggle logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
