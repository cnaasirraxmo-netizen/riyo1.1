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
import 'package:riyo/providers/settings_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  List<StreamSource> _availableSources = [];
  bool _isLoadingSources = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _movieFuture = _apiService.getMovieDetails(widget.movieId, token: auth.token).then((movie) {
          // Always try to fetch fresh sources from the scraping pipeline
          _fetchSources();
          return movie;
        });
        _recommendationsFuture = _apiService.getTrendingMovies(token: auth.token);
      });
      _checkWatchlistStatus();
    });
  }

  void _fetchSources() async {
    if (_movieFuture == null) return;
    final movie = await _movieFuture;
    if (movie == null) return;

    setState(() => _isLoadingSources = true);
    try {
      final id = movie.backendId ?? movie.id.toString();
      final response = await _apiService.getSources(id);
      if (mounted) {
        setState(() {
          final List<dynamic> sourceData = response['sources'] ?? [];
          // Filter to only show admin/local providers
          _availableSources = sourceData
              .map((s) => StreamSource.fromJson(s))
              .where((s) => s.provider == 'admin' || s.provider == 'local')
              .toList();
          _isLoadingSources = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sources: $e');
      if (mounted) {
        setState(() => _isLoadingSources = false);
      }
    }
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

  void _verifyPin(BuildContext context, SettingsProvider settings, VoidCallback onMatched) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Parental Control'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter parental PIN to access this content'),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              if (controller.text == settings.kidsPin) {
                Navigator.pop(context);
                onMatched();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
              }
            },
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading.rectangular(height: 300),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading.rectangular(height: 32, width: 250),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (i) => const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: ShimmerLoading.rectangular(height: 20, width: 60),
                  )),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) => const ShimmerLoading.circular(width: 50, height: 50)),
                ),
                const SizedBox(height: 32),
                const ShimmerLoading.rectangular(height: 56),
                const SizedBox(height: 32),
                const ShimmerLoading.rectangular(height: 100),
                const SizedBox(height: 32),
                const ShimmerLoading.rectangular(height: 40, width: 150),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (i) => const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: ShimmerLoading.rectangular(height: 180, width: 130),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerDetails();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final movie = snapshot.data!;

          if (movie.isTvShow && movie.seasons != null && movie.seasons!.isNotEmpty && _selectedSeason == null) {
            _selectedSeason = movie.seasons![0];
          }

          return CustomScrollView(
            slivers: [
              _buildHeroSection(context, movie),
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
                      if (movie.isTvShow) _buildSeasonSelector(movie),
                      if (movie.isTvShow) _buildEpisodeList(),
                      const SizedBox(height: 32),
                      _buildSourceList(),
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

  Widget _buildHeroSection(BuildContext context, Movie movie) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
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
              placeholder: (context, url) => Image.asset(
                'assets/images/placeholder.jpeg',
                fit: BoxFit.cover,
              ),
              errorWidget: (context, url, error) => Image.asset(
                'assets/images/placeholder.jpeg',
                fit: BoxFit.cover,
              ),
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
                  if (settings.isKidsMode && !movie.isKidsContent) {
                    _verifyPin(context, settings, () {
                      context.push('/movie/$id/play');
                    });
                  } else {
                    context.push('/movie/$id/play');
                  }
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
        if (movie.quality != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              movie.quality!.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        Text(
          movie.title,
          style: AppTypography.headlineLarge,
        ),
        if (movie.shortDesc.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              movie.shortDesc,
              style: AppTypography.titleMedium.copyWith(color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetaItem(Icons.calendar_today_rounded, movie.releaseDate.split('-')[0]),
            _buildMetaItem(Icons.timer_outlined, movie.isTvShow ? 'TV Series' : '${movie.runtime} min'),
            _buildMetaItem(Icons.star_rounded, movie.voteAverage.toStringAsFixed(1), iconColor: Colors.amber),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movie.ageRating ?? '13+',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.language_rounded, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(movie.language ?? 'English', style: AppTypography.labelMedium),
            const SizedBox(width: 16),
            Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(movie.country ?? 'USA', style: AppTypography.labelMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String label, {Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor ?? Colors.grey),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelMedium),
      ],
    );
  }

  void _toggleWatchlist(String? token, String movieId) async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to add movies to your list'),
          action: SnackBarAction(label: 'SIGN IN', onPressed: () => context.push('/login')),
        ),
      );
      return;
    }
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
             _buildActionIconButton(Icons.thumb_up_outlined, 'Rate', onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for rating!')));
             }),
             _buildActionIconButton(Icons.share_rounded, 'Share', onTap: () {
               final id = movie.backendId ?? movie.id.toString();
               Share.share('Check out ${movie.title} on RIYO: https://riyoapp.com/movie/$id');
             }),
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
             final settings = Provider.of<SettingsProvider>(context, listen: false);

             void navigate() {
               if (isComingSoon) {
                  if (movie.trailerUrl != null) {
                    context.push('/movie/$id/play?url=${Uri.encodeComponent(movie.trailerUrl!)}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trailer not available yet')));
                  }
               } else {
                  if (movie.sourceType == 'admin') {
                    final url = movie.directUrl ?? movie.videoUrl;
                    if (url != null && url.isNotEmpty) {
                      context.push('/movie/$id/play?url=${Uri.encodeComponent(url)}&provider=admin');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source URL not available for this movie')));
                    }
                  } else {
                    context.push('/movie/$id/play');
                  }
               }
             }

             if (settings.isKidsMode && !movie.isKidsContent) {
               _verifyPin(context, settings, navigate);
             } else {
               navigate();
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
          final s = _selectedSeason?.number ?? 1;
          final e = episode.number;
          context.push('/movie/${Uri.encodeComponent(widget.movieId)}/play?s=$s&e=$e');
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

  Widget _buildSourceList() {
    if (_isLoadingSources) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Servers', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        ],
      );
    }

    final adminSources = _availableSources.where((s) => s.provider == 'admin' || s.provider == 'local').toList();

    if (adminSources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Servers', style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        const Text('OFFICIAL SERVER', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        ...adminSources.map((s) => _buildSourceItem(s, isOfficial: true)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSourceItem(StreamSource source, {bool isOfficial = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ActionChip(
        backgroundColor: isOfficial ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
        side: isOfficial ? BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)) : null,
        avatar: Icon(
          isOfficial ? Icons.verified_rounded : (source.type == 'embed' ? Icons.launch_rounded : Icons.play_circle_outline_rounded),
          size: 16,
          color: isOfficial ? Colors.amber : null,
        ),
        label: Text('${source.label} (${source.quality})'),
        onPressed: () {
          final id = widget.movieId;
          context.push('/movie/$id/play?url=${Uri.encodeComponent(source.url)}&provider=${source.provider}');
        },
      ),
    );
  }

  Widget _buildMoreInfo(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Information', style: AppTypography.titleLarge),
        const SizedBox(height: 20),
        _buildDetailRow('Director', movie.director ?? 'N/A'),
        _buildDetailRow('Cast', movie.cast?.join(', ') ?? 'N/A'),
        _buildDetailRow('Genres', movie.genres?.join(', ') ?? 'N/A'),
        _buildDetailRow('Language', movie.language ?? 'English'),
        _buildDetailRow('Country', movie.country ?? 'United States'),
        if (movie.tags != null && movie.tags!.isNotEmpty)
          _buildDetailRow('Tags', movie.tags!.join(' #')),
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
