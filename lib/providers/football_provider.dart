import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riyobox/models/football.dart';
import 'package:riyobox/services/football_service.dart';
import 'package:riyobox/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FootballProvider with ChangeNotifier {
  final FootballService _service = FootballService();
  Timer? _refreshTimer;

  List<FootballFixture> _fixtures = [];
  List<FootballStanding> _standings = [];
  List<FootballPlayerStats> _topScorers = [];
  List<Map<String, dynamic>> _teams = [];
  List<int> _followedTeams = [];

  bool _isLoadingFixtures = false;
  bool _isLoadingStandings = false;
  bool _isLoadingScorers = false;
  bool _isLoadingTeams = false;

  String? _error;

  List<FootballFixture> get fixtures => _fixtures;
  List<FootballStanding> get standings => _standings;
  List<FootballPlayerStats> get topScorers => _topScorers;
  List<Map<String, dynamic>> get teams => _teams;
  List<int> get followedTeams => _followedTeams;

  bool get isLoading => _isLoadingFixtures || _isLoadingStandings || _isLoadingScorers || _isLoadingTeams;
  bool get isLoadingFixtures => _isLoadingFixtures;

  String? get error => _error;

  int _selectedLeague = 39;
  int _selectedSeason = 2024;

  int get selectedLeague => _selectedLeague;
  int get selectedSeason => _selectedSeason;

  FootballProvider() {
    _loadFromCache();
  }

  void setLeague(int league) {
    _selectedLeague = league;
    fetchAll();
  }

  void toggleFollowTeam(int teamId) {
    if (_followedTeams.contains(teamId)) {
      _followedTeams.remove(teamId);
    } else {
      _followedTeams.add(teamId);
    }
    _saveToCache();
    notifyListeners();
  }

  bool isFollowing(int teamId) => _followedTeams.contains(teamId);

  void fetchAll() {
    fetchFixtures(league: _selectedLeague, season: _selectedSeason);
    fetchStandings(_selectedLeague, _selectedSeason);
    fetchTopScorers(_selectedLeague, _selectedSeason);
    fetchTeams(_selectedLeague, _selectedSeason);
  }

  void startLivePolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Only refresh fixtures when polling
      fetchFixtures(league: _selectedLeague, season: _selectedSeason, silent: true);
    });
  }

  void stopLivePolling() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final fixturesJson = prefs.getString('football_fixtures');
      if (fixturesJson != null) {
        final List<dynamic> decoded = jsonDecode(fixturesJson);
        _fixtures = decoded.map((item) => FootballFixture.fromJson(item)).toList();
      }

      final standingsJson = prefs.getString('football_standings');
      if (standingsJson != null) {
        final List<dynamic> decoded = jsonDecode(standingsJson);
        _standings = decoded.map((item) => FootballStanding.fromJson(item)).toList();
      }

      final scorersJson = prefs.getString('football_topscorers');
      if (scorersJson != null) {
        final List<dynamic> decoded = jsonDecode(scorersJson);
        _topScorers = decoded.map((item) => FootballPlayerStats.fromJson(item)).toList();
      }

      final followedJson = prefs.getString('football_followed');
      if (followedJson != null) {
        _followedTeams = List<int>.from(jsonDecode(followedJson));
      }

      notifyListeners();
    } catch (e) {
      print('Error loading football cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('football_fixtures', jsonEncode(_fixtures.map((f) => f.toJson()).toList()));
      await prefs.setString('football_standings', jsonEncode(_standings.map((s) => s.toJson()).toList()));
      await prefs.setString('football_topscorers', jsonEncode(_topScorers.map((p) => p.toJson()).toList()));
      await prefs.setString('football_followed', jsonEncode(_followedTeams));
    } catch (e) {
      print('Error saving football cache: $e');
    }
  }

  Future<void> fetchFixtures({int? league, int? season, bool silent = false}) async {
    if (!silent) {
      _isLoadingFixtures = true;
      _error = null;
      notifyListeners();
    }

    try {
      final newFixtures = await _service.getFixtures(league: league, season: season);

      // Check for score changes if not first load
      if (_fixtures.isNotEmpty && silent) {
        for (var newFix in newFixtures) {
          final oldFix = _fixtures.firstWhere((f) => f.id == newFix.id, orElse: () => newFix);
          if (oldFix != newFix && (oldFix.homeGoals != newFix.homeGoals || oldFix.awayGoals != newFix.awayGoals)) {
             // Score changed!
             // Only notify if we follow one of the teams or no teams are followed (notify all)
             if (_followedTeams.isEmpty ||
                 _followedTeams.contains(newFix.homeTeamId) ||
                 _followedTeams.contains(newFix.awayTeamId)) {
               NotificationService().showNotification(
                 id: newFix.id,
                 title: 'GOAL! ${newFix.homeTeam} ${newFix.homeGoals} - ${newFix.awayGoals} ${newFix.awayTeam}',
                 body: '${newFix.leagueName} match update',
               );
             }
          }
        }
      }

      _fixtures = newFixtures;
      await _saveToCache();
    } catch (e) {
      if (!silent) _error = e.toString();
    } finally {
      if (!silent) {
        _isLoadingFixtures = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchStandings(int league, int season) async {
    _isLoadingStandings = true;
    _error = null;
    notifyListeners();

    try {
      _standings = await _service.getStandings(league, season);
      await _saveToCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingStandings = false;
      notifyListeners();
    }
  }

  Future<void> fetchTopScorers(int league, int season) async {
    _isLoadingScorers = true;
    _error = null;
    notifyListeners();

    try {
      _topScorers = await _service.getTopScorers(league, season);
      await _saveToCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingScorers = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeams(int league, int season) async {
    _isLoadingTeams = true;
    _error = null;
    notifyListeners();

    try {
      _teams = await _service.getTeams(league, season);
      await _saveToCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingTeams = false;
      notifyListeners();
    }
  }

  Future<List<FootballPlayerStats>> getTeamPlayers(int teamId) async {
    try {
      return await _service.getTeamPlayers(teamId, _selectedSeason);
    } catch (e) {
      print('Error fetching team players: $e');
      return [];
    }
  }
}
