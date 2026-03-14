import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riyo/models/movie.dart';
import 'package:riyo/core/constants.dart';

class ApiService {
  static const String _backendUrl = Constants.apiBaseUrl;

  Future<Map<String, List<Movie>>> getHomeData() async {
    final response = await http.get(Uri.parse('$_backendUrl/api/v1/home'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'trendingMovies': _parseList(data['trendingMovies']),
        'popularMovies': _parseList(data['popularMovies']),
        'topRatedMovies': _parseList(data['topRatedMovies']),
        'trendingTV': _parseList(data['trendingTV']),
      };
    }
    throw Exception('Failed to load home data');
  }

  List<Movie> _parseList(dynamic data) {
    if (data == null) return [];
    return (data as List).map((json) => Movie.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getSources(String id, {int? season, int? episode}) async {
    String url = '$_backendUrl/api/v1/movie/$id/sources';
    if (season != null && episode != null) {
      url = '$_backendUrl/api/v1/tv/$id/sources/$season/$episode';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<List<Movie>> search(String query) async {
    final response = await http.get(Uri.parse('$_backendUrl/api/v1/search?query=$query'));
    if (response.statusCode == 200) {
      return _parseList(json.decode(response.body));
    }
    return [];
  }
}
