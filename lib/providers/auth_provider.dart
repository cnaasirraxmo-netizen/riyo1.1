import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riyobox/core/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider with ChangeNotifier {
  static const String _backendUrl = Constants.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;
  String? _token;
  String? _role;
  Map<String, dynamic>? _userAccount;
  Map<String, dynamic>? _activeProfile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboardingComplete => _isOnboardingComplete;
  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get userAccount => _userAccount;
  Map<String, dynamic>? get activeProfile => _activeProfile;

  AuthProvider() {
    _loadState();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _isAuthenticated = false;
        _token = null;
        _userAccount = null;
      } else {
        _isAuthenticated = true;
        _token = await user.getIdToken();
        await fetchAccount();
        await _syncFcmToken();
      }
      notifyListeners();
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboardingComplete = prefs.getBool('isOnboardingComplete') ?? false;
    notifyListeners();
  }

  Future<void> fetchAccount() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/users/account'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        _userAccount = jsonDecode(response.body);
        _role = _userAccount?['role'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching account: $e');
    }
  }

  Future<void> selectProfile(String profileId) async {
    if (_token == null) return;
    try {
      final response = await http.put(
        Uri.parse('$_backendUrl/users/profiles/active'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'profileId': profileId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activeProfile = data['profile'];
        notifyListeners();
      }
    } catch (e) {
      print('Error selecting profile: $e');
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signupWithEmail(String name, String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await result.user?.updateDisplayName(name);
      // Sync with backend will happen via authStateChanges listener
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('Google Sign-In failed');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _isAuthenticated = false;
    _token = null;
    _userAccount = null;
    _activeProfile = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isOnboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    notifyListeners();
  }

  Future<void> _syncFcmToken() async {
    if (_token == null) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await http.post(
          Uri.parse('$_backendUrl/users/fcm-token'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': fcmToken}),
        );
      }
    } catch (e) {
      print('Error syncing FCM token: $e');
    }
  }

  Future<void> deleteAccount() async {
    if (_auth.currentUser == null) return;
    try {
      // 1. Delete from backend (GDPR)
      await http.delete(
        Uri.parse('$_backendUrl/users/account'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      // 2. Delete from Firebase
      await _auth.currentUser?.delete();
      await logout();
    } catch (e) {
      print('Error deleting account: $e');
    }
  }
}
