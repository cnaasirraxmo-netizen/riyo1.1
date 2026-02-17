import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riyobox/models/movie.dart';
import 'package:riyobox/core/constants.dart';

class ApiService {
  static const String _backendUrl = Constants.apiBaseUrl;

  Future<List<Movie>> getTrendingMovies({String? token, String? genre}) async {
    return getMovies(token: token, genre: genre, isTrending: true);
  }

  Future<List<Movie>> getMovies({
    String? token,
    String? genre,
    String? search,
    int? year,
    double? rating,
    String? sort,
    bool? isTrending,
  }) async {
    try {
      if (token != null) {
        var uri = Uri.parse('$_backendUrl/movies').replace(queryParameters: {
          if (genre != null) 'genre': genre,
          if (search != null) 'search': search,
          if (year != null) 'year': year.toString(),
          if (rating != null) 'rating': rating.toString(),
          if (sort != null) 'sort': sort,
          if (isTrending != null) 'isTrending': isTrending.toString(),
        });

        final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final List<dynamic> results = json.decode(response.body);
          return results.map((json) => Movie.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error fetching movies: $e');
    }
    return [];
  }

  Future<List<Movie>> getTopRatedMovies({String? token}) async {
    return getMovies(token: token, sort: 'rating');
  }

  Future<List<Movie>> getNowPlayingMovies({String? token}) async {
    return getMovies(token: token, sort: 'newest');
  }

  Future<Movie> getMovieDetails(String movieId, {String? token}) async {
    try {
      if (token != null) {
        final response = await http.get(Uri.parse('$_backendUrl/movies/$movieId'), headers: {'Authorization': 'Bearer $token'});
        if (response.statusCode == 200) return Movie.fromJson(json.decode(response.body));
      }
    } catch (e) { print('Error fetching movie details: $e'); }
    throw Exception('Failed to load movie details');
  }

  Future<bool> addReview(String movieId, String token, double rating, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/movies/$movieId/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
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
      print('Error toggling watchlist: $e');
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
      print('Error fetching watchlist: $e');
    }
    return [];
  }
}
