import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riyo/models/movie.dart';
import 'package:riyo/core/constants.dart';
import 'package:riyo/services/local_cache_service.dart';

class ApiService {
  static const String _backendUrl = Constants.apiBaseUrl;
  final LocalCacheService _cacheService = LocalCacheService();

  Future<T> _cacheThenNetwork<T>({
    required String cacheKey,
    required String url,
    required T Function(dynamic data) parser,
    Map<String, String>? headers,
  }) async {
    // 1. Try to get from cache first for fast response
    final cached = _cacheService.getCachedData(cacheKey);
    T? cachedResult;
    if (cached != null) {
      try {
        cachedResult = parser(cached);
      } catch (e) {
        debugPrint('Cache parsing error for $cacheKey: $e');
      }
    }

    // 2. Fetch from network
    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Save to cache asynchronously
        unawaited(_cacheService.cacheData(cacheKey, data));
        return parser(data);
      }
    } catch (e) {
      debugPrint('ApiService network error for $url: $e');
    }

    // 3. Fallback to cache if network failed
    if (cachedResult != null) return cachedResult;

    throw Exception('Failed to load data from network and no cache available');
  }

  Future<Map<String, List<Movie>>> getHomeData() async {
    return _cacheThenNetwork<Map<String, List<Movie>>>(
      cacheKey: 'home_data_aggregate',
      url: '$_backendUrl/api/v1/home',
      parser: (data) {
        return {
          'trendingMovies': _parseList(data['trendingMovies']),
          'popularMovies': _parseList(data['popularMovies']),
          'topRatedMovies': _parseList(data['topRatedMovies']),
          'trendingTV': _parseList(data['trendingTV']),
        };
      },
    );
  }

  Future<Map<String, dynamic>> getSources(String id, {int? season, int? episode}) async {
    String url = '$_backendUrl/api/v1/movie/$id/sources';
    if (season != null && episode != null) {
      url = '$_backendUrl/api/v1/tv/$id/sources/$season/$episode';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('ApiService.getSources error: $e');
    }
    return {'sources': [], 'subtitles': []};
  }

  Future<List<Movie>> getTrendingMovies({String? token, String? genre, bool isFeatured = false, int page = 1, int limit = 20}) async {
    String url = '$_backendUrl/movies';
    final List<String> params = [];
    if (genre != null) params.add('genre=$genre');
    if (isFeatured) params.add('isFeatured=true');
    params.add('page=$page');
    params.add('limit=$limit');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final cacheKey = 'movies_list_${genre ?? 'all'}_${isFeatured}_${page}_${limit}';

    try {
      return await _cacheThenNetwork<List<Movie>>(
        cacheKey: cacheKey,
        url: url,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        parser: (data) => _parseList(data),
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Movie>> getTopRatedMovies({String? token, int page = 1, int limit = 20}) async {
    return getTrendingMovies(token: token, page: page, limit: limit);
  }

  Future<List<Movie>> getNowPlayingMovies({String? token, int page = 1, int limit = 20}) async {
    return getTrendingMovies(token: token, page: page, limit: limit);
  }

  Future<Movie> getMovieDetails(String movieId, {String? token}) async {
    final cacheKey = 'movie_details_$movieId';
    return _cacheThenNetwork<Movie>(
      cacheKey: cacheKey,
      url: '$_backendUrl/movies/$movieId',
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      parser: (data) => Movie.fromJson(data),
    );
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
    const cacheKey = 'header_categories';
    try {
      return await _cacheThenNetwork<List<String>>(
        cacheKey: cacheKey,
        url: '$_backendUrl/config/categories',
        parser: (data) {
          final List<dynamic> list = data is List ? data : [];
          return list.map((cat) => cat['name'].toString()).toList();
        },
      );
    } catch (e) {
      return ["All", "Movies", "TV Shows", "Anime", "Kids", "My List"];
    }
  }

  Future<List<Map<String, dynamic>>> getHomeSections() async {
    const cacheKey = 'home_sections_config';
    try {
      return await _cacheThenNetwork<List<Map<String, dynamic>>>(
        cacheKey: cacheKey,
        url: '$_backendUrl/config/home-sections',
        parser: (data) {
          final List<dynamic> list = data is List ? data : [];
          return List<Map<String, dynamic>>.from(list);
        },
      );
    } catch (e) {
      return [
        {'title': 'Trending Now', 'type': 'trending'},
        {'title': 'Popular on RIYO', 'type': 'top_rated'},
        {'title': 'New Releases', 'type': 'new_releases'},
      ];
    }
  }

  Future<List<Movie>> getComingSoonMovies({String? token}) async {
    const cacheKey = 'coming_soon_movies';
    try {
      return await _cacheThenNetwork<List<Movie>>(
        cacheKey: cacheKey,
        url: '$_backendUrl/movies/coming-soon',
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        parser: (data) => _parseList(data),
      );
    } catch (e) {
      return [];
    }
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
