
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';
import 'package:riyo/services/local_cache_service.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final double height;

  const MovieCard({super.key, required this.movie, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final id = movie.backendId ?? movie.id.toString();
        context.push('/movie/$id');
      },
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                    ? AppColors.lightBorder
                    : AppColors.darkBorder,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: movie.posterPath.isNotEmpty
                  ? (movie.posterPath.startsWith('http')
                      ? movie.posterPath
                      : 'https://image.tmdb.org/t/p/w500${movie.posterPath}')
                  : '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Image.asset(
                'assets/images/placeholder.jpeg',
                fit: BoxFit.cover,
              ),
              errorWidget: (context, url, error) => Image.asset(
                'assets/images/placeholder.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (movie.contentType == 'premium')
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: movie.sourceType == 'admin' ? Colors.green : Colors.blueAccent.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movie.sourceType == 'admin' ? 'DIRECT PLAY' : 'STREAM',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (movie.isDownloaded || LocalCacheService().getCachedMovie(movie.backendId ?? movie.id.toString()) != null)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  movie.isDownloaded ? Icons.check_circle : Icons.offline_pin_rounded,
                  color: movie.isDownloaded ? Colors.green : Colors.blueAccent,
                  size: 18,
                ),
              ),
            ),
          if (movie.isDownloading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.cardBorderRadius)),
                child: LinearProgressIndicator(
                  value: movie.downloadProgress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary),
                  minHeight: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
