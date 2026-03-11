import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riyo/core/constants.dart';
import 'package:riyo/models/user.dart';
import 'package:flutter/material.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isOnboardingComplete;
  final String? token;
  final String? role;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isOnboardingComplete = false,
    this.token,
    this.role,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isOnboardingComplete,
    String? token,
    String? role,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      token: token ?? this.token,
      role: role ?? this.role,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends fr.Notifier<AuthState> {
  static const String _backendUrl = Constants.apiBaseUrl;

  @override
  AuthState build() {
    _loadState();
    return AuthState(isLoading: true);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    final isOnboardingComplete = prefs.getBool('isOnboardingComplete') ?? false;
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final userJson = prefs.getString('user');

    User? user;
    if (userJson != null) {
      user = User.fromJson(jsonDecode(userJson));
    }

    state = AuthState(
      isAuthenticated: isAuthenticated,
      isOnboardingComplete: isOnboardingComplete,
      token: token,
      role: role,
      user: user,
      isLoading: false,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];
        final user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('user', jsonEncode(user.toJson()));

        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          role: role,
          user: user,
          isLoading: false,
        );
      } else {
        final errorMsg = _parseErrorMessage(response);
        state = state.copyWith(isLoading: false, error: errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = e is http.ClientException || e.toString().contains('SocketException')
          ? 'Unable to connect to the server.'
          : e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];
        final user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('user', jsonEncode(user.toJson()));

        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          role: role,
          user: user,
          isLoading: false,
        );
      } else {
        final errorMsg = _parseErrorMessage(response);
        state = state.copyWith(isLoading: false, error: errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = e is http.ClientException || e.toString().contains('SocketException')
          ? 'Unable to connect to the server.'
          : e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user');

    state = state.copyWith(
      isAuthenticated: false,
      token: null,
      role: null,
      user: null,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    state = state.copyWith(isOnboardingComplete: true);
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Status Code: ${response.statusCode}';
    } catch (_) {
      return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
    }
  }
}

final authProvider = fr.NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
