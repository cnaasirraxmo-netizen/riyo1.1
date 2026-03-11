import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riyo/models/movie.dart';
import 'package:riyo/core/constants.dart';

class ApiService {
  static const String _apiKey = Constants.tmdbApiKey;
  static const String _baseUrl = Constants.tmdbBaseUrl;
  static const String _backendUrl = Constants.apiBaseUrl;

  bool get _isMock => _apiKey == 'YOUR_API_KEY';

  Future<Map<String, dynamic>> getTrendingMovies(
      {String? token, String? genre, bool isFeatured = false, String? cursor}) async {
    try {
      if (token != null) {
        String url = '$_backendUrl/movies';
        final List<String> params = [];
        if (genre != null) params.add('genre=$genre');
        if (isFeatured) params.add('isFeatured=true');
        if (cursor != null) params.add('lastId=$cursor');

        if (params.isNotEmpty) {
          url += '?${params.join('&')}';
        }

        final response = await http.get(Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'}).timeout(
            const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<Movie> results = (data['movies'] as List).map((m) => Movie.fromJson(m)).toList();
          return {
            'movies': results,
            'nextCursor': data['nextCursor'],
          };
        }
      }
    } catch (e) {}

    return {
      'movies': <Movie>[],
      'nextCursor': null,
    };
  }

  Future<Map<String, dynamic>> getTopRatedMovies({String? token, String? cursor}) async {
    return getTrendingMovies(token: token, cursor: cursor);
  }

  Future<Map<String, dynamic>> getNowPlayingMovies({String? token, String? cursor}) async {
    return getTrendingMovies(token: token, cursor: cursor);
  }

  Future<Movie> getMovieDetails(String movieId, {String? token}) async {
    try {
      if (token != null) {
        final response = await http.get(Uri.parse('$_backendUrl/movies/$movieId'), headers: {'Authorization': 'Bearer $token'});
        if (response.statusCode == 200) return Movie.fromJson(json.decode(response.body));
      }
    } catch (e) {}
    throw Exception('Failed to load movie details');
  }

  Future<List<Movie>> getComingSoonMoviesList({String? token}) async {
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
    } catch (e) {}
    return [];
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
    } catch (e) {}
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
    return ["All", "Movies", "TV Shows", "Anime", "Kids", "My List"];
  }

  Future<List<Map<String, dynamic>>> getHomeSections() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/config/home-sections'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {}
    return [];
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
    } catch (e) {}
    return false;
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
    } catch (e) {}
    return false;
  }
}
