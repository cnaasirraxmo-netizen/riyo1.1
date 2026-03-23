
import 'package:flutter/material.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<String> _categories = ["All", "Movies", "TV Shows", "Anime", "Kids", "My List"];
  List<Map<String, dynamic>> _sections = [
    {'title': 'RIYOBOX EXCLUSIVES', 'type': 'admin_only'},
    {'title': 'Trending Movies', 'type': 'trending_new'},
    {'title': 'Popular Movies', 'type': 'popular_new'},
    {'title': 'Top Rated', 'type': 'top_rated_new'},
    {'title': 'TV Shows', 'type': 'trending_tv_new'},
  ];
  Map<String, Future<List<Movie>>> _sectionFutures = {};
  Future<List<Movie>>? _featuredFuture;

  bool _isLoadingConfig = false;
  String _selectedCategory = "All";

  List<String> get categories => _categories;
  List<Map<String, dynamic>> get sections => _sections;
  bool get isLoadingConfig => _isLoadingConfig;
  String get selectedCategory => _selectedCategory;
  Future<List<Movie>>? get featuredFuture => _featuredFuture;

  Future<List<Movie>> getSectionFuture(String title, String type, {String? genre, String? token}) {
    if (_sectionFutures.containsKey(title)) {
      return _sectionFutures[title]!;
    }

    Future<List<Movie>> future;
    switch (type) {
      case 'trending':
        future = _apiService.getTrendingMovies(token: token);
        break;
      case 'top_rated':
        future = _apiService.getTopRatedMovies(token: token);
        break;
      case 'new_releases':
        future = _apiService.getNowPlayingMovies(token: token);
        break;
      case 'genre':
        future = _apiService.getTrendingMovies(token: token, genre: genre);
        break;
      case 'admin_only':
        future = _apiService.getAdminMovies(token: token);
        break;
      default:
        future = Future.value([]);
    }

    _sectionFutures[title] = future;
    return future;
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  bool _isDataLoaded = false;
  bool get isDataLoaded => _isDataLoaded;

  Future<void> loadConfig({String? token, bool forceRefresh = false}) async {
    if (_isDataLoaded && !forceRefresh) return;

    // We don't set _isLoadingConfig = true here to avoid full screen loaders
    // Instead, sections will show shimmers if their futures are pending

    try {
      // Background fetch categories but keep hardcoded ones as base
      _apiService.getHeaderCategories().then((cats) {
         _categories = cats;
         notifyListeners();
      });

      // Use new aggregation route for home data
      final homeData = await _apiService.getHomeData();

      if (homeData['trendingMovies']!.isEmpty && _isDataLoaded) {
        // Don't overwrite existing UI data if network fails and returns empty Map
        return;
      }

      _sectionFutures.clear();
      _sectionFutures['RIYOBOX EXCLUSIVES'] = Future.value(homeData['adminMovies']);

      final List<Movie> trendingWithAdmin = [
        ...(homeData['adminMovies'] ?? []).take(5), // Prioritize new admin content
        ...(homeData['trendingMovies'] ?? []),
      ];
      _sectionFutures['Trending Movies'] = Future.value(trendingWithAdmin);

      _sectionFutures['Popular Movies'] = Future.value(homeData['popularMovies']);
      _sectionFutures['Top Rated'] = Future.value(homeData['topRatedMovies']);
      _sectionFutures['TV Shows'] = Future.value(homeData['trendingTV']);

      final featured = homeData['trendingMovies']?.take(5).toList() ?? [];
      _featuredFuture = Future.value(featured);
      _isDataLoaded = true;

      // Deep pre-caching for improved UX
      for (var movie in featured) {
        if (movie.videoUrl != null) {
          _apiService.preCacheVideo(movie.videoUrl!);
        }
        // Cache detailed info immediately
        _apiService.getMovieDetails(movie.backendId ?? movie.id.toString(), token: token);
      }

      // Cache admin content immediately
      for (var movie in (homeData['adminMovies'] ?? []).take(5)) {
         _apiService.getMovieDetails(movie.backendId ?? movie.id.toString(), token: token);
      }
    } catch (e) {
      debugPrint('Error loading home config: $e');
    } finally {
      _isLoadingConfig = false;
      notifyListeners();
    }
  }

  void refresh() {
    _isDataLoaded = false;
    _sectionFutures.clear();
    _featuredFuture = null;
    notifyListeners();
  }
}
