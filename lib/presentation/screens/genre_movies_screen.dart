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
  final ScrollController _scrollController = ScrollController();

  final List<Movie> _movies = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreMovies();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _movies.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final movies = await _fetchPage(1);
      setState(() {
        _movies.addAll(movies);
        _isLoading = false;
        if (movies.length < 20) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMoreMovies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final movies = await _fetchPage(nextPage);

      setState(() {
        _currentPage = nextPage;
        _movies.addAll(movies);
        _isLoading = false;
        if (movies.length < 20) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Movie>> _fetchPage(int page) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (widget.genreName == 'Watchlist' || widget.genreName == 'MY WATCHLIST') {
      // Watchlist usually doesn't have offset pagination in this backend yet,
      // but we'll fetch all or just one page for now.
      if (page > 1) return [];
      return _apiService.getWatchlist(auth.token ?? "");
    } else if (widget.genreName == 'Trending Now') {
      return _apiService.getTrendingMovies(token: auth.token, page: page);
    } else if (widget.genreName == 'Popular on RIYO') {
      return _apiService.getTopRatedMovies(token: auth.token, page: page);
    } else if (widget.genreName == 'New Releases') {
      return _apiService.getNowPlayingMovies(token: auth.token, page: page);
    } else {
      return _apiService.getTrendingMovies(token: auth.token, genre: widget.genreName, page: page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.genreName, style: AppTypography.titleLarge),
        surfaceTintColor: Colors.transparent,
      ),
      body: _movies.isEmpty && _isLoading
        ? _buildLoadingGrid()
        : _error != null
          ? _buildErrorView()
          : _movies.isEmpty
            ? _buildEmptyView()
            : _buildMovieGrid(),
    );
  }

  Widget _buildMovieGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _movies.length + (_hasMore ? 3 : 0),
      itemBuilder: (context, index) {
        if (index < _movies.length) {
          return MovieCard(movie: _movies[index]);
        } else {
          return const ShimmerLoading.rectangular(height: 160);
        }
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Failed to load movies', style: AppTypography.bodyMedium),
          TextButton(onPressed: _loadInitialData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
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

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => const ShimmerLoading.rectangular(height: 160),
    );
  }
}
