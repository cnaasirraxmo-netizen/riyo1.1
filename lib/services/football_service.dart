import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riyobox/core/constants.dart';
import 'package:riyobox/models/football.dart';

class FootballService {
  static const String _backendUrl = '${Constants.apiBaseUrl}/sports';

  Future<List<FootballFixture>> getFixtures({int? league, int? season}) async {
    String url = '$_backendUrl/fixtures?';
    if (league != null) url += 'league=$league&';
    if (season != null) url += 'season=$season&';
    if (league == null && season == null) url += 'live=all';

    final response = await http.get(Uri.parse(url));

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
      Uri.parse('$_backendUrl/standings?league=$league&season=$season'),
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
      Uri.parse('$_backendUrl/topscorers?league=$league&season=$season'),
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
      Uri.parse('$_backendUrl/teams?league=$league&season=$season'),
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
      Uri.parse('$_backendUrl/players?team=$teamId&season=$season'),
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
