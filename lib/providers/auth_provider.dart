import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riyo/core/constants.dart';
import 'package:riyo/models/user.dart';

class AuthProvider with ChangeNotifier {
  static const String _backendUrl = Constants.apiBaseUrl;
  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;
  String? _token;
  String? _role;
  User? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboardingComplete => _isOnboardingComplete;
  String? get token => _token;
  String? get role => _role;
  User? get user => _user;

  AuthProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _isOnboardingComplete = prefs.getBool('isOnboardingComplete') ?? false;
    _token = prefs.getString('token');
    _role = prefs.getString('role');

    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }

    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _role = data['role'];
        _user = User.fromJson(data);
        _isAuthenticated = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
      } else {
        final errorMsg = _parseErrorMessage(response);
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is http.ClientException || e.toString().contains('SocketException')) {
        throw Exception('Unable to connect to the server. Please check your internet connection and ensure the backend is running.');
      }
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _role = data['role'];
        _user = User.fromJson(data);
        _isAuthenticated = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
      } else {
        final errorMsg = _parseErrorMessage(response);
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is http.ClientException || e.toString().contains('SocketException')) {
        throw Exception('Unable to connect to the server. Please check your internet connection and ensure the backend is running.');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _role = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user');
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isOnboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    notifyListeners();
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Status Code: ${response.statusCode}';
    } catch (_) {
      return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
    }
  }

  Future<bool> checkSession() async {
    // Simulate API token validation
    await Future.delayed(const Duration(milliseconds: 500));
    if (_token == null) {
      _isAuthenticated = false;
      return false;
    }
    // Assume token is valid if present for this mock
    return true;
  }
}
