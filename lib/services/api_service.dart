import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riyo/models/movie.dart';
import 'package:riyo/core/constants.dart';
import 'package:riyo/services/local_cache_service.dart';

class ApiService {
  static const String _backendUrl = Constants.apiBaseUrl;
  final LocalCacheService _cacheService = LocalCacheService();

  // NEW AGGREGATION METHODS
  Future<Map<String, List<Movie>>> getHomeData() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/api/v1/home')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache data for offline
        _cacheService.cacheMovieList('home_trendingMovies', List<Map<String, dynamic>>.from(data['trendingMovies'] ?? []));
        _cacheService.cacheMovieList('home_popularMovies', List<Map<String, dynamic>>.from(data['popularMovies'] ?? []));
        _cacheService.cacheMovieList('home_topRatedMovies', List<Map<String, dynamic>>.from(data['topRatedMovies'] ?? []));
        _cacheService.cacheMovieList('home_trendingTV', List<Map<String, dynamic>>.from(data['trendingTV'] ?? []));

        return {
          'trendingMovies': _parseList(data['trendingMovies']),
          'popularMovies': _parseList(data['popularMovies']),
          'topRatedMovies': _parseList(data['topRatedMovies']),
          'trendingTV': _parseList(data['trendingTV']),
        };
      }
    } catch (e) {
      debugPrint('ApiService.getHomeData error: $e. Using cache.');
    }

    // Offline fallback
    return {
      'trendingMovies': _parseList(_cacheService.getCachedMovieList('home_trendingMovies')),
      'popularMovies': _parseList(_cacheService.getCachedMovieList('home_popularMovies')),
      'topRatedMovies': _parseList(_cacheService.getCachedMovieList('home_topRatedMovies')),
      'trendingTV': _parseList(_cacheService.getCachedMovieList('home_trendingTV')),
    };
  }

  Future<Map<String, dynamic>> getSources(String id, {int? season, int? episode}) async {
    String url = '$_backendUrl/api/v1/movie/$id/sources';
    if (season != null && episode != null) {
      url = '$_backendUrl/api/v1/tv/$id/sources/$season/$episode';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    return {'sources': [], 'subtitles': []};
  }

  // RESTORED METHODS TO FIX CI COMPILATION ERRORS

  Future<List<Movie>> getTrendingMovies({String? token, String? genre, bool isFeatured = false, int page = 1, int limit = 20}) async {
    String url = '$_backendUrl/movies';
    final List<String> params = [];
    if (genre != null) params.add('genre=$genre');
    if (isFeatured) params.add('isFeatured=true');
    params.add('page=$page');
    params.add('limit=$limit');

    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http.get(
      Uri.parse(url),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
    if (response.statusCode == 200) {
      return _parseList(json.decode(response.body));
    }
    return [];
  }

  Future<List<Movie>> getTopRatedMovies({String? token, int page = 1, int limit = 20}) async {
    return getTrendingMovies(token: token, page: page, limit: limit);
  }

  Future<List<Movie>> getNowPlayingMovies({String? token, int page = 1, int limit = 20}) async {
    return getTrendingMovies(token: token, page: page, limit: limit);
  }

  Future<Movie> getMovieDetails(String movieId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/movies/$movieId'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cacheService.cacheMovie(movieId, data);
        return Movie.fromJson(data);
      }
    } catch (e) {
      debugPrint('ApiService.getMovieDetails error: $e. Using cache.');
    }

    final cached = _cacheService.getCachedMovie(movieId);
    if (cached != null) {
      return Movie.fromJson(cached);
    }
    throw Exception('Failed to load movie details');
  }

  Future<bool> toggleWatchlist(String movieId, String token) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/users/watchlist/$movieId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['isAdded'] ?? false;
    }
    return false;
  }

  Future<List<Movie>> getWatchlist(String token) async {
    final response = await http.get(
      Uri.parse('$_backendUrl/users/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseList(data['watchlist']);
    }
    return [];
  }

  Future<List<String>> getHeaderCategories() async {
    final response = await http.get(Uri.parse('$_backendUrl/config/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((cat) => cat['name'].toString()).toList();
    }
    return ["All", "Movies", "TV Shows", "Anime", "Kids", "My List"];
  }

  Future<List<Map<String, dynamic>>> getHomeSections() async {
    final response = await http.get(Uri.parse('$_backendUrl/config/home-sections'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [
      {'title': 'Trending Now', 'type': 'trending'},
      {'title': 'Popular on RIYO', 'type': 'top_rated'},
      {'title': 'New Releases', 'type': 'new_releases'},
    ];
  }

  Future<List<Movie>> getComingSoonMovies({String? token}) async {
    final response = await http.get(
      Uri.parse('$_backendUrl/movies/coming-soon'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
    if (response.statusCode == 200) {
      return _parseList(json.decode(response.body));
    }
    return [];
  }

  Future<bool> toggleNotifyMe(String movieId, String token) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/users/notify-me/$movieId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['isNotified'] ?? false;
    }
    return false;
  }

  Future<List<Movie>> search(String query) async {
    final response = await http.get(Uri.parse('$_backendUrl/api/v1/search?query=$query'));
    if (response.statusCode == 200) {
      return _parseList(json.decode(response.body));
    }
    return [];
  }

  List<Movie> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is Map && data.containsKey('movies')) {
      return (data['movies'] as List).map((json) => Movie.fromJson(json)).toList();
    }
    if (data is List) {
      return data.map((json) => Movie.fromJson(json)).toList();
    }
    return [];
  }
}
