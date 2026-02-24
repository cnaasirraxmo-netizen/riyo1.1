import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/providers/auth_provider.dart';
import 'package:riyobox/providers/download_provider.dart';
import 'package:riyobox/services/cast_service.dart';
import 'package:riyobox/models/movie.dart';
import 'package:riyobox/services/api_service.dart';
import 'package:riyobox/presentation/widgets/movie_card.dart';
import 'package:riyobox/presentation/widgets/shimmer_loading.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailsScreen({super.key, required this.movieId});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final ApiService _apiService = ApiService();
  Season? _selectedSeason;
  bool _isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: FutureBuilder<Movie>(
        future: _apiService.getMovieDetails(widget.movieId, token: auth.token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final movie = snapshot.data!;

          // Check if movie is in watchlist (ideally backend returns this in movie details)
          // For now, we can check it if we had a full profile in auth provider or separate call

          if (movie.isTvShow && movie.seasons != null && _selectedSeason == null) {
            _selectedSeason = movie.seasons![0];
          }

          return CustomScrollView(
            slivers: [
              _buildHeroSection(movie),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildMainInfo(movie),
                      const SizedBox(height: 24),
                      _buildActionsBar(context, movie),
                      const SizedBox(height: 24),
                      _buildBadges(),
                      const SizedBox(height: 24),
                      _buildSynopsis(movie),
                      const SizedBox(height: 24),
                      _buildCastSection(movie),
                      const SizedBox(height: 32),
                      if (movie.isTvShow) _buildSeasonSelector(movie),
                      if (movie.isTvShow) _buildEpisodeList(),
                      const SizedBox(height: 32),
                      _buildMoreInfo(movie),
                      const SizedBox(height: 40),
                      _buildRecommendationsSection("MORE LIKE THIS"),
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
      expandedHeight: 250,
      pinned: true,
      backgroundColor: const Color(0xFF141414),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.cast, color: Colors.white),
          onPressed: () => context.push('/cast'),
        ),
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
              placeholder: (context, url) => const ShimmerLoading.rectangular(height: 250),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black45,
                    Colors.transparent,
                    Color(0xFF141414),
                  ],
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  final id = movie.backendId ?? movie.id.toString();
                  context.push('/movie/$id/play');
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.play_arrow, size: 60, color: Colors.white),
                ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Poster overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: movie.posterPath.startsWith('http') ? movie.posterPath : 'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerLoading.rectangular(width: 100, height: 150),
                  ),
                ),
                if (movie.contentType == 'premium')
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(2)),
                      child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsRow(movie),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              movie.releaseDate.split('-')[0],
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movie.contentRating ?? '13+',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              movie.isTvShow ? 'TV Series' : '${movie.runtime} min',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.hd_outlined, color: Colors.grey, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.yellow, size: 18),
            const SizedBox(width: 4),
            Text(
              movie.voteAverage.toStringAsFixed(1),
              style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Text(
              'TMDB RATING',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
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
    final castService = Provider.of<CastService>(context);
    final downloads = Provider.of<DownloadProvider>(context);
    final bool isDownloaded = downloads.isDownloaded(movie.id);
    final bool isDownloading = downloads.isDownloading(movie.id);
    final double progress = downloads.getDownloadProgress(movie.id);
    final bool isComingSoon = movie.contentType == 'coming_soon';

    return Column(
      children: [
        Row(
          children: [
             Expanded(
               child: _buildActionIconButton(
                 _isInWatchlist ? Icons.check : Icons.add,
                 'MY LIST',
                 onTap: () => _toggleWatchlist(auth.token, movie.backendId ?? movie.id.toString())
               ),
             ),
             Expanded(
               child: _buildActionIconButton(Icons.thumb_up_alt_outlined, 'RATE'),
             ),
             Expanded(
               child: _buildActionIconButton(Icons.share_outlined, 'SHARE'),
             ),
             if (castService.isConnected && !isComingSoon)
               Expanded(
                 child: _buildActionIconButton(
                   Icons.cast_connected,
                   'CAST',
                   onTap: () => castService.loadMedia(
                     movie.videoUrl ?? '',
                     title: movie.title,
                     posterUrl: movie.posterPath
                   )
                 ),
               ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
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
            icon: Icon(isComingSoon ? Icons.play_circle_outline : Icons.play_arrow, color: Colors.black),
            label: Text(isComingSoon ? 'WATCH TRAILER' : 'RESUME', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: isComingSoon
            ? OutlinedButton.icon(
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
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                label: const Text('NOTIFY ME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              )
            : isDownloading
            ? Column(
                children: [
                  LinearProgressIndicator(value: progress, color: Colors.deepPurpleAccent, backgroundColor: Colors.white10),
                  const SizedBox(height: 8),
                  Text('Downloading... ${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            : ElevatedButton.icon(
                onPressed: isDownloaded ? null : () => downloads.startDownload(movie),
                icon: Icon(isDownloaded ? Icons.download_done : Icons.download, color: Colors.white),
                label: Text(isDownloaded ? 'DOWNLOADED' : 'DOWNLOAD', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF262626),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildActionIconButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return const Wrap(
      spacing: 8,
      children: [
        _Badge(text: 'RIYO ORIGINAL', color: Colors.deepPurpleAccent),
        _Badge(text: 'TRENDING NOW', color: Colors.redAccent),
      ],
    );
  }

  bool _isSynopsisExpanded = false;

  Widget _buildSynopsis(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.overview,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          maxLines: _isSynopsisExpanded ? null : 3,
          overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
          child: Text(
            _isSynopsisExpanded ? 'SHOW LESS' : 'READ MORE',
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCastSection(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CAST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movie.cast?.length ?? 0,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF262626),
                      child: Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(movie.cast![index], style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showSeasonPicker(movie),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF262626),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedSeason?.title ?? 'Select Season', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  void _showSeasonPicker(Movie movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: movie.seasons?.length ?? 0,
          itemBuilder: (context, index) {
            final season = movie.seasons![index];
            return ListTile(
              title: Text(season.title, style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _selectedSeason = season);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEpisodeList() {
    if (_selectedSeason == null) return const SizedBox();
    return Column(
      children: _selectedSeason!.episodes.map((episode) => _buildEpisodeItem(episode)).toList(),
    );
  }

  Widget _buildEpisodeItem(Episode episode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 130,
                  height: 75,
                  color: const Color(0xFF262626),
                  child: const Center(child: Icon(Icons.play_arrow, color: Colors.white, size: 32)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${episode.number}. ${episode.title}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(episode.duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'In this episode, the story continues as our heroes face new challenges and unexpected turns.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreInfo(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildDetailRow('Director', movie.director ?? 'N/A'),
        _buildDetailRow('Genres', movie.genres?.join(', ') ?? 'N/A'),
        _buildDetailRow('Maturity Rating', movie.contentRating ?? '13+'),
        _buildDetailRow('Audio', 'English, Somali, Arabic'),
        _buildDetailRow('Subtitles', 'English, Arabic'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            TextSpan(text: value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(String title) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        FutureBuilder<List<Movie>>(
          future: _apiService.getTrendingMovies(token: auth.token),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 180, child: ShimmerLoading.rectangular(height: 180));
            final movies = snapshot.data!;
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MovieCard(movie: movies[index], height: 180),
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
