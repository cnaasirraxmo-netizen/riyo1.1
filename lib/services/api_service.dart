import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
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
    final cached = _cacheService.getCachedData(cacheKey);
    T? cachedResult;
    if (cached != null) {
      try {
        cachedResult = parser(cached);
      } catch (e) {
        debugPrint('Cache parsing error for $cacheKey: $e');
      }
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        unawaited(_cacheService.cacheData(cacheKey, data));
        return parser(data);
      }
    } catch (e) {
      debugPrint('ApiService network error for $url: $e');
    }

    if (cachedResult != null) return cachedResult;
    throw Exception('network-request-failed');
  }

  // NEW AGGREGATION METHODS
  Future<Map<String, List<Movie>>> getHomeData() async {
    return await _cacheThenNetwork<Map<String, List<Movie>>>(
      cacheKey: 'home_data_aggregate',
      url: '$_backendUrl/api/v1/home',
      parser: (data) => {
        'adminMovies': _parseList(data['adminMovies']),
        'trendingMovies': _parseList(data['trendingMovies']),
        'popularMovies': _parseList(data['popularMovies']),
        'topRatedMovies': _parseList(data['topRatedMovies']),
        'trendingTV': _parseList(data['trendingTV']),
      },
    );
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

  Future<List<Movie>> getTrendingMovies({String? token, String? genre, bool isFeatured = false, String? sourceType, int page = 1, int limit = 20}) async {
    String url = '$_backendUrl/movies';
    final List<String> params = [];
    if (genre != null) params.add('genre=$genre');
    if (isFeatured) params.add('isFeatured=true');
    if (sourceType != null) params.add('sourceType=$sourceType');
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

  Future<List<Movie>> getAdminMovies({String? token, int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$_backendUrl/movies/admin?page=$page&limit=$limit'),
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
    return await _cacheThenNetwork<Movie>(
      cacheKey: 'movie_details_$movieId',
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

  Future<List<Movie>> getKidsHome() async {
    const cacheKey = 'kids_home_data';
    try {
      return await _cacheThenNetwork<List<Movie>>(
        cacheKey: cacheKey,
        url: '$_backendUrl/api/v1/kids/home',
        parser: (data) => _parseList(data),
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Movie>> search(String query) async {
    return await _cacheThenNetwork<List<Movie>>(
      cacheKey: 'search_results_${query.replaceAll(' ', '_')}',
      url: '$_backendUrl/api/v1/search?query=$query',
      parser: (data) => _parseList(data),
    );
  }

  Future<void> preCacheVideo(String url) async {
    if (kIsWeb) return;
    try {
      final dioClient = dio.Dio();
      await dioClient.get(
        url,
        options: dio.Options(
          headers: {'Range': 'bytes=0-1048576'}, // First 1MB
          responseType: dio.ResponseType.bytes,
        ),
      );
      debugPrint('Pre-cached 1MB of video: $url');
    } catch (e) {
      debugPrint('Pre-cache error: $e');
    }
  }

  List<Movie> _parseList(dynamic data) {
    try {
      if (data == null) return [];

      List<dynamic> list = [];
      if (data is Map && data.containsKey('movies')) {
        list = data['movies'] as List;
      } else if (data is List) {
        list = data;
      }

      return list.map((json) {
        try {
          return Movie.fromJson(Map<String, dynamic>.from(json));
        } catch (e) {
          debugPrint('Error parsing individual movie: $e');
          // Return a mock or empty movie to prevent the whole list from failing
          return null;
        }
      }).whereType<Movie>().toList();
    } catch (e) {
      debugPrint('Critical error in _parseList: $e');
      return [];
    }
  }
}
