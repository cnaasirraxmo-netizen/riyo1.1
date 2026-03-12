import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/services/notification_service.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen> {
  final ApiService _apiService = ApiService();
  List<Movie> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final movies = await _apiService.getComingSoonMovies(token: token);
    if (mounted) {
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coming Soon', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _movies.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _movies.length,
                  itemBuilder: (context, index) => _buildComingSoonItem(_movies[index]),
                ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 24.0),
        child: ShimmerLoading.rectangular(height: 250),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 80, color: Theme.of(context).colorScheme.primary.withAlpha(50)),
          const SizedBox(height: 16),
          Text('No upcoming releases yet', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text('Check back later for new content', style: AppTypography.labelSmall),
        ],
      ),
    );
  }

  Widget _buildComingSoonItem(Movie movie) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.amoledSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (movie.trailerUrl != null) {
                context.push(
                    '/movie/${movie.backendId ?? movie.id}/play?url=${Uri.encodeComponent(movie.trailerUrl!)}');
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: (movie.backdropPath ?? movie.posterPath).startsWith('http')
                      ? (movie.backdropPath ?? movie.posterPath)
                      : 'https://image.tmdb.org/t/p/w780${movie.backdropPath ?? movie.posterPath}',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerLoading.rectangular(height: 200),
                ),
                Container(
                  height: 200,
                  color: Colors.black26,
                ),
                if (movie.trailerUrl != null)
                  const Icon(Icons.play_circle_outline_rounded, size: 56, color: Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        movie.title,
                        style: AppTypography.titleLarge,
                      ),
                    ),
                    _buildNotifyButton(movie),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Coming ${movie.releaseDate.split('-')[0]}',
                  style: AppTypography.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  movie.overview,
                  style: AppTypography.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (movie.genres != null && movie.genres!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.genres!
                        .map((g) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(g,
                                  style: AppTypography.labelSmall.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifyButton(Movie movie) {
    final auth = Provider.of<AuthProvider>(context);

    return IconButton.filledTonal(
      onPressed: () async {
        if (!auth.isAuthenticated) {
          context.push('/login');
          return;
        }

        await NotificationService.initialize();
        final res = await _apiService.toggleNotifyMe(
            movie.backendId ?? movie.id.toString(), auth.token!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res
              ? 'We\'ll notify you when ${movie.title} is available!'
              : 'Notifications disabled'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        _fetchMovies();
      },
      icon: const Icon(Icons.notifications_none_rounded),
    );
  }
}
