import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/models/movie.dart';
import 'package:riyobox/services/api_service.dart';
import 'package:riyobox/providers/auth_provider.dart';
import 'package:riyobox/services/notification_service.dart';
import 'package:riyobox/presentation/widgets/shimmer_loading.dart';
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
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('COMING SOON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: _isLoading
        ? _buildLoadingState()
        : _movies.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _movies.length,
              itemBuilder: (context, index) => _buildComingSoonItem(_movies[index]),
            ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: ShimmerLoading.rectangular(height: 250),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 80, color: Colors.white10),
          SizedBox(height: 16),
          Text('No upcoming releases yet.', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildComingSoonItem(Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trailer/Backdrop with Play Icon
          GestureDetector(
            onTap: () {
               if (movie.trailerUrl != null) {
                  context.push('/movie/${movie.backendId ?? movie.id}/play?url=${Uri.encodeComponent(movie.trailerUrl!)}');
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
                ),
                Container(
                  height: 200,
                  color: Colors.black26,
                ),
                if (movie.trailerUrl != null)
                  const Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        movie.title,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildNotifyButton(movie),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Coming this ${movie.releaseDate.split('-')[0]}',
                  style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  movie.overview,
                  style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: (movie.genres ?? []).map((g) => Chip(
                    label: Text(g, style: const TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: Colors.white10,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildNotifyButton(Movie movie) {
    final auth = Provider.of<AuthProvider>(context);
    // In a real app, we would check if the user is already in movie.notifyUsers
    // For now we'll simulate based on the snackbar feedback

    return OutlinedButton.icon(
      onPressed: () async {
        if (!auth.isAuthenticated) {
          if (!mounted) return;
          context.push('/login');
          return;
        }

        // Request notification permissions again just in case
        await NotificationService.initialize();

        final res = await _apiService.toggleNotifyMe(movie.backendId ?? movie.id.toString(), auth.token!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res ? 'Push notifications enabled for ${movie.title}!' : 'Notifications disabled'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: res ? Colors.green : Colors.redAccent,
          )
        );
        _fetchMovies();
      },
      icon: const Icon(Icons.notifications_active_outlined, size: 18),
      label: const Text('NOTIFY ME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
