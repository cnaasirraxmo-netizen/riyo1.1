import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/download_provider.dart';
import 'package:riyo/core/casting/presentation/providers/casting_provider.dart';
import 'package:riyo/core/casting/domain/entities/cast_media.dart';
import 'package:riyo/core/casting/presentation/widgets/cast_button.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/presentation/widgets/movie_card.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;

class MovieDetailsScreen extends rp.ConsumerStatefulWidget {
  final String movieId;

  const MovieDetailsScreen({super.key, required this.movieId});

  @override
  rp.ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends rp.ConsumerState<MovieDetailsScreen> {
  final ApiService _apiService = ApiService();
  Season? _selectedSeason;
  bool _isInWatchlist = false;
  Future<Movie>? _movieFuture;
  Future<List<Movie>>? _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _movieFuture = _apiService.getMovieDetails(widget.movieId, token: auth.token);
        _recommendationsFuture = _apiService.getTrendingMovies(token: auth.token);
      });
      _checkWatchlistStatus();
    });
  }

  void _checkWatchlistStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated || auth.token == null) return;

    final watchlist = await _apiService.getWatchlist(auth.token!);
    if (mounted) {
      setState(() {
        _isInWatchlist = watchlist.any((m) => (m.backendId ?? m.id.toString()) == widget.movieId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final movie = snapshot.data!;

          if (movie.isTvShow && movie.seasons != null && _selectedSeason == null) {
            _selectedSeason = movie.seasons![0];
          }

          return CustomScrollView(
            slivers: [
              _buildHeroSection(movie),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainInfo(movie),
                      const SizedBox(height: 32),
                      _buildActionsBar(context, movie),
                      const SizedBox(height: 32),
                      _buildSynopsis(movie),
                      const SizedBox(height: 32),
                      _buildCastSection(movie),
                      const SizedBox(height: 32),
                      if (movie.isTvShow) _buildSeasonSelector(movie),
                      if (movie.isTvShow) _buildEpisodeList(),
                      const SizedBox(height: 32),
                      _buildMoreInfo(movie),
                      const SizedBox(height: 48),
                      _buildRecommendationsSection("More Like This"),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(Movie movie) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        const CastingButton(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: (movie.backdropPath ?? movie.posterPath).startsWith('http')
                  ? (movie.backdropPath ?? movie.posterPath)
                  : 'https://image.tmdb.org/t/p/original${movie.backdropPath ?? movie.posterPath}',
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerLoading.rectangular(height: 300),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Center(
              child: FloatingActionButton.large(
                onPressed: () {
                  final id = movie.backendId ?? movie.id.toString();
                  context.push('/movie/$id/play');
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.play_arrow_rounded, size: 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: AppTypography.headlineLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              movie.releaseDate.split('-')[0],
              style: AppTypography.labelMedium,
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movie.contentRating ?? '13+',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              movie.isTvShow ? 'TV Series' : '${movie.runtime} min',
              style: AppTypography.labelMedium,
            ),
            const Spacer(),
            Icon(Icons.star_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              movie.voteAverage.toStringAsFixed(1),
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleWatchlist(String? token, String movieId) async {
    if (token == null) return;
    final res = await _apiService.toggleWatchlist(movieId, token);
    setState(() {
      _isInWatchlist = res;
    });
  }

  Widget _buildActionsBar(BuildContext context, Movie movie) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final downloads = Provider.of<DownloadProvider>(context);
    final bool isDownloaded = downloads.isDownloaded(movie.id);
    final bool isDownloading = downloads.isDownloading(movie.id);
    final double progress = downloads.getDownloadProgress(movie.id);
    final bool isComingSoon = movie.contentType == 'coming_soon';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             _buildActionIconButton(
               _isInWatchlist ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
               'My List',
               onTap: () => _toggleWatchlist(auth.token, movie.backendId ?? movie.id.toString())
             ),
             _buildActionIconButton(Icons.thumb_up_outlined, 'Rate'),
             _buildActionIconButton(Icons.share_rounded, 'Share'),
             if (ref.watch(castingProvider).connectedDevice != null && !isComingSoon)
               _buildActionIconButton(
                 Icons.cast_connected,
                 'Cast',
                 onTap: () => ref.read(castingProvider.notifier).castMedia(
                   CastMedia(
                     url: movie.videoUrl ?? '',
                     title: movie.title,
                     posterUrl: movie.posterPath,
                   ),
                 )
               ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
             final id = movie.backendId ?? movie.id.toString();
             if (isComingSoon) {
                if (movie.trailerUrl != null) {
                  context.push('/movie/$id/play?url=${Uri.encodeComponent(movie.trailerUrl!)}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trailer not available yet')));
                }
             } else {
                context.push('/movie/$id/play');
             }
          },
          icon: Icon(isComingSoon ? Icons.play_circle_outline : Icons.play_arrow_rounded),
          label: Text(isComingSoon ? 'Watch Trailer' : 'Play Now'),
        ),
        const SizedBox(height: 16),
        if (isComingSoon)
          OutlinedButton.icon(
            onPressed: () async {
              if (!auth.isAuthenticated) {
                context.push('/login');
                return;
              }
              final res = await _apiService.toggleNotifyMe(movie.backendId ?? movie.id.toString(), auth.token!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res ? 'We will notify you when it is released!' : 'Notifications disabled'))
                );
              }
            },
            icon: const Icon(Icons.notifications_none_rounded),
            label: const Text('Notify Me'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius)),
            ),
          )
        else if (isDownloading)
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: progress, minHeight: 4),
              ),
              const SizedBox(height: 8),
              Text('Downloading... ${(progress * 100).toStringAsFixed(0)}%', style: AppTypography.labelSmall),
            ],
          )
        else
          TextButton.icon(
            onPressed: isDownloaded ? null : () => downloads.startDownload(movie),
            icon: Icon(isDownloaded ? Icons.download_done_rounded : Icons.download_rounded),
            label: Text(isDownloaded ? 'Downloaded' : 'Download Offline'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildActionIconButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }

  bool _isSynopsisExpanded = false;

  Widget _buildSynopsis(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.overview,
          style: AppTypography.bodyMedium.copyWith(height: 1.6),
          maxLines: _isSynopsisExpanded ? null : 4,
          overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
          child: Text(
            _isSynopsisExpanded ? 'Show Less' : 'Read More',
            style: AppTypography.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCastSection(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cast', style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movie.cast?.length ?? 0,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                      child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(movie.cast![index], style: AppTypography.labelSmall),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonSelector(Movie movie) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: OutlinedButton.icon(
        onPressed: () => _showSeasonPicker(movie),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        label: Text(_selectedSeason?.title ?? 'Select Season'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showSeasonPicker(Movie movie) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: movie.seasons?.length ?? 0,
            itemBuilder: (context, index) {
              final season = movie.seasons![index];
              return ListTile(
                title: Text(season.title, style: AppTypography.titleMedium),
                onTap: () {
                  setState(() => _selectedSeason = season);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEpisodeList() {
    if (_selectedSeason == null) return const SizedBox();
    return Column(
      children: _selectedSeason!.episodes
          .map((episode) => _buildEpisodeItem(episode))
          .toList(),
    );
  }

  Widget _buildEpisodeItem(Episode episode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () {
          if (episode.videoUrl != null) {
            context.push(
                '/movie/${widget.movieId}/play?url=${Uri.encodeComponent(episode.videoUrl!)}');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    height: 80,
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    child: const Center(
                        child: Icon(Icons.play_circle_fill_rounded, size: 32)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${episode.number}. ${episode.title}',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(episode.duration, style: AppTypography.labelSmall),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.download_for_offline_outlined),
                    onPressed: () {}),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enjoy the latest episode of ${episode.title}. High quality streaming available.',
              style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).textTheme.labelSmall?.color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreInfo(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        _buildDetailRow('Director', movie.director ?? 'N/A'),
        _buildDetailRow('Genres', movie.genres?.join(', ') ?? 'N/A'),
        _buildDetailRow('Maturity', movie.contentRating ?? '13+'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: AppTypography.labelLarge.copyWith(color: Theme.of(context).textTheme.labelSmall?.color)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        FutureBuilder<List<Movie>>(
          future: _recommendationsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 210, child: ShimmerLoading.rectangular(height: 210));
            final movies = snapshot.data!;
            return SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(width: 140, child: MovieCard(movie: movies[index], height: 210)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
