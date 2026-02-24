import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/presentation/widgets/movie_card.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';

class GenreMoviesScreen extends StatefulWidget {
  final String genreName;

  const GenreMoviesScreen({super.key, required this.genreName});

  @override
  State<GenreMoviesScreen> createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends State<GenreMoviesScreen> {
  final ApiService _apiService = ApiService();
  Future<List<Movie>>? _moviesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMovies();
    });
  }

  void _loadMovies() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      if (widget.genreName == 'Watchlist' || widget.genreName == 'MY WATCHLIST') {
        _moviesFuture = _apiService.getWatchlist(auth.token ?? "");
      } else if (widget.genreName == 'Trending Now') {
        _moviesFuture = _apiService.getTrendingMovies(token: auth.token);
      } else if (widget.genreName == 'Popular on RIYO') {
        _moviesFuture = _apiService.getTopRatedMovies(token: auth.token);
      } else if (widget.genreName == 'New Releases') {
        _moviesFuture = _apiService.getNowPlayingMovies(token: auth.token);
      } else {
        _moviesFuture = _apiService.getTrendingMovies(token: auth.token, genre: widget.genreName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: Text(widget.genreName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Movie>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingGrid();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_outlined,
                      size: 80, color: Colors.white10),
                  const SizedBox(height: 16),
                  Text('No movies found in ${widget.genreName}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }

          final movies = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: MovieCard(movie: movie, height: 160)),
                  const SizedBox(height: 4),
                  Text(
                    movie.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${movie.releaseDate.split('-')[0]}${movie.runtime != null ? " | ${_formatDuration(movie.runtime!)}" : ""}',
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                ],
              );
            },
          );
        },
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

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 9,
      itemBuilder: (context, index) => const ShimmerLoading.rectangular(height: 160),
    );
  }
}
