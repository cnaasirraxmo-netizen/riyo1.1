import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
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
      appBar: AppBar(
        title: Text(widget.genreName, style: AppTypography.titleLarge),
        surfaceTintColor: Colors.transparent,
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
                  Icon(Icons.movie_filter_rounded,
                      size: 80, color: Theme.of(context).colorScheme.primary.withAlpha(50)),
                  const SizedBox(height: 16),
                  Text('No movies found', style: AppTypography.bodyMedium),
                ],
              ),
            );
          }

          final movies = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return MovieCard(movie: movies[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
