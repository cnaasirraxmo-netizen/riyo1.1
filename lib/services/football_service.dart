import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riyobox/core/constants.dart';
import 'package:riyobox/models/football.dart';

class FootballService {
  static const String _apiKey = Constants.footballApiKey;
  static const String _baseUrl = Constants.footballBaseUrl;

  Map<String, String> get _headers => {
    'x-apisports-key': _apiKey,
  };

  Future<List<FootballFixture>> getFixtures({int? league, int? season}) async {
    String url = '$_baseUrl/fixtures?';
    if (league != null) url += 'league=$league&';
    if (season != null) url += 'season=$season&';
    // If no params, maybe get live fixtures
    if (league == null && season == null) url += 'live=all';

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['response'];
      return results.map((json) => FootballFixture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load fixtures');
    }
  }

  Future<List<FootballStanding>> getStandings(int league, int season) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/standings?league=$league&season=$season'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['response'].isEmpty) return [];
      final List<dynamic> standings = data['response'][0]['league']['standings'][0];
      return standings.map((json) => FootballStanding.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load standings');
    }
  }

  Future<List<FootballPlayerStats>> getTopScorers(int league, int season) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/players/topscorers?league=$league&season=$season'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['response'];
      return results.map((json) => FootballPlayerStats.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load top scorers');
    }
  }

  Future<List<Map<String, dynamic>>> getTeams(int league, int season) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/teams?league=$league&season=$season'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['response'];
      return results.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<List<FootballPlayerStats>> getTeamPlayers(int teamId, int season) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/players?team=$teamId&season=$season'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['response'];
      return results.map((json) => FootballPlayerStats.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load team players');
    }
  }
}
