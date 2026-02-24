import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riyo/models/movie.dart';
import 'package:riyo/core/constants.dart';

class ApiService {
  static const String _apiKey = Constants.tmdbApiKey;
  static const String _baseUrl = Constants.tmdbBaseUrl;
  static const String _backendUrl = Constants.apiBaseUrl;

  // Simple In-memory cache
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  bool get _isMock => _apiKey == 'YOUR_API_KEY';

  Future<List<Movie>> getTrendingMovies(
      {String? token, String? genre, bool isFeatured = false}) async {
    final cacheKey = 'trending_${genre}_$isFeatured';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<Movie>;
    }

    try {
      if (token != null) {
        String url = '$_backendUrl/movies';
        final List<String> params = [];
        if (genre != null) params.add('genre=$genre');
        if (isFeatured) params.add('isFeatured=true');

        if (params.isNotEmpty) {
          url += '?${params.join('&')}';
        }

        final response = await http.get(Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'}).timeout(
            const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final List<Movie> results = await compute(_parseMovies, response.body);
          _setCache(cacheKey, results);
          return results;
        }
      }
    } catch (e) {
      debugPrint('Error fetching from backend: $e');
      if (e.toString().contains('SocketException')) {
        debugPrint('Backend connection failed. Is the server running?');
      }
    }
    if (_isMock) return _getMockMovies();
    return _fetchMovies('/trending/movie/day');
  }

  Future<List<Movie>> getTopRatedMovies({String? token}) async {
    const cacheKey = 'top_rated';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey] as List<Movie>;

    if (token != null) return getTrendingMovies(token: token);
    if (_isMock) return _getMockMovies();
    final results = await _fetchMovies('/movie/top_rated');
    _setCache(cacheKey, results);
    return results;
  }

  Future<List<Movie>> getNowPlayingMovies({String? token}) async {
    const cacheKey = 'now_playing';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey] as List<Movie>;

    if (token != null) return getTrendingMovies(token: token);
    if (_isMock) return _getMockMovies();
    final results = await _fetchMovies('/movie/now_playing');
    _setCache(cacheKey, results);
    return results;
  }

  Future<Movie> getMovieDetails(String movieId, {String? token}) async {
    try {
      if (token != null) {
        final response = await http.get(Uri.parse('$_backendUrl/movies/$movieId'), headers: {'Authorization': 'Bearer $token'});
        if (response.statusCode == 200) return Movie.fromJson(json.decode(response.body));
      }
    } catch (e) { debugPrint('Error fetching movie details from backend: $e'); }
    if (_isMock) {
      final movies = await _getMockMovies();
      final movie = movies.firstWhere((m) => m.id.toString() == movieId,
          orElse: () => movies[0]);

      // If it's The Boys, add seasons
      if (movie.id == 6) {
        return Movie(
          id: movie.id,
          title: movie.title,
          overview: movie.overview,
          posterPath: movie.posterPath,
          backdropPath: movie.backdropPath,
          releaseDate: movie.releaseDate,
          voteAverage: movie.voteAverage,
          runtime: 60,
          genres: ['Action', 'Sci-Fi', 'Comedy'],
          cast: ['Karl Urban', 'Jack Quaid', 'Antony Starr'],
          director: 'Eric Kripke',
          contentRating: 'R',
          isTvShow: true,
          seasons: [
            Season(
              number: 1,
              title: 'Season 1 (2019)',
              episodes: [
                Episode(number: 1, title: 'The Name of the Game', duration: '60min'),
                Episode(number: 2, title: 'Cherry', duration: '56min'),
                Episode(number: 3, title: 'Get Some', duration: '58min'),
                Episode(number: 4, title: 'The Female of the Species', duration: '55min'),
              ],
            ),
            Season(
              number: 2,
              title: 'Season 2 (2020)',
              episodes: [
                Episode(number: 1, title: 'The Big Ride', duration: '62min'),
              ],
            ),
          ],
        );
      }

      return Movie(
        id: movie.id,
        title: movie.title,
        overview: movie.overview,
        posterPath: movie.posterPath,
        backdropPath: movie.backdropPath,
        releaseDate: movie.releaseDate,
        voteAverage: movie.voteAverage,
        runtime: 148,
        genres: ['Action', 'Sci-Fi', 'Adventure'],
        cast: ['Actor 1', 'Actor 2', 'Actor 3'],
        director: 'John Director',
        contentRating: 'PG-13',
      );
    }
    final response =
        await http.get(Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey'));

    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  Future<List<Movie>> _fetchMovies(String url) async {
    final response =
        await http.get(Uri.parse('$_baseUrl$url?api_key=$_apiKey'));

    if (response.statusCode == 200) {
      return await compute(_parseMovies, response.body);
    } else {
      throw Exception('Failed to load movies');
    }
  }

  static List<Movie> _parseMovies(String responseBody) {
    final data = json.decode(responseBody);
    final List<dynamic> results = (data is List)
        ? data
        : (data['movies'] ?? data['results'] ?? []);
    return results.map((json) => Movie.fromJson(json)).toList();
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final time = _cacheTime[key];
    if (time == null) return false;
    if (DateTime.now().difference(time) > _cacheDuration) {
      _cache.remove(key);
      _cacheTime.remove(key);
      return false;
    }
    return true;
  }

  void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTime[key] = DateTime.now();
  }

  Future<List<Movie>> _getMockMovies() async {
    // Test movies removed as requested.
    return [];
  }

  Future<List<Movie>> getSimilarMovies(String movieId) async {
    final all = await _getMockMovies();
    return all.where((m) => m.id.toString() != movieId).take(4).toList();
  }

  Future<List<Movie>> getMoviesByDirector(String director) async {
    final all = await _getMockMovies();
    return all.take(2).toList();
  }

  Future<bool> toggleWatchlist(String movieId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/users/watchlist/$movieId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isAdded'];
      }
    } catch (e) {
      debugPrint('Error toggling watchlist: $e');
    }
    return false;
  }

  Future<List<Movie>> getWatchlist(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> watchlist = data['watchlist'];
        return watchlist.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching watchlist: $e');
    }
    return [];
  }

  Future<List<String>> getHeaderCategories() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/config/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((cat) => cat['name'].toString()).toList();
      }
    } catch (e) {}
    return ["All", "Movies", "TV Shows", "Anime", "Kids", "My List"]; // Fallback
  }

  Future<List<Map<String, dynamic>>> getHomeSections() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/config/home-sections'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {}
    return [
      {'title': 'Trending Now', 'type': 'trending'},
      {'title': 'Popular on RIYO', 'type': 'top_rated'},
      {'title': 'New Releases', 'type': 'new_releases'},
    ]; // Fallback
  }

  Future<List<Movie>> getComingSoonMovies({String? token}) async {
    try {
      final url = '$_backendUrl/movies/coming-soon';
      final response = await http.get(
        Uri.parse(url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching coming soon: $e');
    }
    return [];
  }

  Future<bool> toggleNotifyMe(String movieId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/users/notify-me/$movieId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isNotified'];
      }
    } catch (e) {
      debugPrint('Error toggling notification: $e');
    }
    return false;
  }
}
