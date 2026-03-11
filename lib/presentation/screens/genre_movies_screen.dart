import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/presentation/providers/auth_provider.dart';
import 'package:riyo/presentation/widgets/movie_card.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';

class GenreMoviesScreen extends ConsumerStatefulWidget {
  final String genreName;

  const GenreMoviesScreen({super.key, required this.genreName});

  @override
  ConsumerState<GenreMoviesScreen> createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends ConsumerState<GenreMoviesScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Movie> _movies = [];
  String? _nextCursor;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMovies(initial: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _nextCursor != null) {
        _loadMovies();
      }
    }
  }

  Future<void> _loadMovies({bool initial = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (initial) _hasError = false;
    });

    try {
      final auth = ref.read(authProvider);
      final Map<String, dynamic> res;

      if (widget.genreName == 'Watchlist' || widget.genreName == 'MY WATCHLIST') {
        final watchlist = await _apiService.getWatchlist(auth.token ?? "");
        res = {'movies': watchlist, 'nextCursor': null};
      } else if (widget.genreName == 'Trending Now') {
        res = await _apiService.getTrendingMovies(token: auth.token, cursor: _nextCursor);
      } else if (widget.genreName == 'Popular on RIYO') {
        res = await _apiService.getTopRatedMovies(token: auth.token, cursor: _nextCursor);
      } else if (widget.genreName == 'New Releases') {
        res = await _apiService.getNowPlayingMovies(token: auth.token, cursor: _nextCursor);
      } else {
        res = await _apiService.getTrendingMovies(token: auth.token, genre: widget.genreName, cursor: _nextCursor);
      }

      final List<Movie> newMovies = List<Movie>.from(res['movies']);

      if (mounted) {
        setState(() {
          if (initial) {
            _movies = newMovies;
          } else {
            _movies.addAll(newMovies);
          }
          _nextCursor = res['nextCursor'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (initial) _hasError = true;
        });
      }
    }
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
      body: _movies.isEmpty && _isLoading
          ? _buildLoadingGrid()
          : _movies.isEmpty && !_isLoading
          ? Center(
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
            )
          : GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _movies.length + (_isLoading ? 3 : 0),
            itemBuilder: (context, index) {
              if (index >= _movies.length) {
                 return const ShimmerLoading.rectangular(height: 160);
              }
              final movie = _movies[index];
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
                ],
              );
            },
          ),
    );
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
