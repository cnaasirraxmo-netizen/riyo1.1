import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riyobox/core/constants.dart';
import 'package:riyobox/models/movie.dart';

class AuthProvider with ChangeNotifier {
  static const String _backendUrl = Constants.apiBaseUrl;
  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;
  String? _token;
  String? _role;
  Map<String, dynamic>? _userProfile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboardingComplete => _isOnboardingComplete;
  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get userProfile => _userProfile;

  AuthProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _isOnboardingComplete = prefs.getBool('isOnboardingComplete') ?? false;
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    if (_isAuthenticated && _token != null) {
      fetchProfile();
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/users/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        _userProfile = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> updateProfile({String? name, String? bio, String? profilePicture, Map<String, dynamic>? preferences}) async {
    if (_token == null) return;
    try {
      final response = await http.put(
        Uri.parse('$_backendUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (profilePicture != null) 'profilePicture': profilePicture,
          if (preferences != null) 'preferences': preferences,
        }),
      );
      if (response.statusCode == 200) {
        _userProfile = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
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
        _isAuthenticated = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        await fetchProfile();
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
        _isAuthenticated = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        await fetchProfile();
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
    _userProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('token');
    await prefs.remove('role');
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isOnboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_token == null) return;
    try {
      final response = await http.delete(
        Uri.parse('$_backendUrl/users/account'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        await logout();
      }
    } catch (e) {
      print('Error deleting account: $e');
    }
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
    await Future.delayed(const Duration(milliseconds: 500));
    if (_token == null) {
      _isAuthenticated = false;
      return false;
    }
    return true;
  }
}
