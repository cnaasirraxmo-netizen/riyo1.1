import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riyo/core/constants.dart';
import 'package:riyo/models/user.dart';
import 'package:riyo/services/notification_service.dart';
import 'package:riyo/services/analytics_service.dart';

class AuthProvider with ChangeNotifier {
  fb.FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  static const String _backendUrl = Constants.apiBaseUrl;
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isOnboardingComplete = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isGuest => _isGuest;
  String? _token;
  String? _role;
  User? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboardingComplete => _isOnboardingComplete;
  String? get token => _token;
  String? get role => _role;
  User? get user => _user;

  AuthProvider() {
    try {
      _auth = fb.FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
    } catch (e) {
      debugPrint('Error initializing AuthProvider dependencies: $e');
    }
    _loadState().catchError((e) {
      debugPrint('Error loading AuthProvider state: $e');
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _isGuest = prefs.getBool('isGuest') ?? false;
    _isOnboardingComplete = prefs.getBool('isOnboardingComplete') ?? false;
    _token = prefs.getString('token');
    _role = prefs.getString('role');

    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (_auth == null) throw Exception("Firebase Auth not initialized");
    try {
      // 1. Firebase Login
      final fb.UserCredential credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String? idToken = await credential.user?.getIdToken();
      if (idToken == null) throw Exception("Failed to get ID Token from Firebase");
      final String? fcmToken = await NotificationService.getToken();

      // 2. Backend Sync/Login
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'firebaseToken': idToken,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _handleLoginSuccess(data);
        AnalyticsService.logUserLogin('email');
      } else {
        await _auth?.signOut();
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> signup(String name, String email, String password, {String? phoneNumber}) async {
    if (_auth == null) throw Exception("Firebase Auth not initialized");
    try {
      // 1. Firebase Signup
      final fb.UserCredential credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);

      final String? idToken = await credential.user?.getIdToken();
      if (idToken == null) throw Exception("Failed to get ID Token from Firebase");
      final String? fcmToken = await NotificationService.getToken();

      // 2. Backend Signup
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'firebaseToken': idToken,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _handleLoginSuccess(data);
        AnalyticsService.logUserSignUp('email');
      } else {
        await credential.user?.delete();
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateProfile({String? name, String? phoneNumber}) async {
    if (_token == null) return;
    try {
      final response = await http.put(
        Uri.parse('$_backendUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'name': name,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Refresh local user data
        final currentData = _user?.toJson() ?? {};
        if (name != null) currentData['name'] = name;
        if (phoneNumber != null) currentData['phoneNumber'] = phoneNumber;

        _user = User.fromJson(currentData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (_token == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (_token == null) return;
    try {
      final response = await http.delete(
        Uri.parse('$_backendUrl/users/account'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await logout();
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    if (_googleSignIn == null || _auth == null) throw Exception("Google Sign-In/Firebase not initialized");
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb.UserCredential userCredential = await _auth!.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();
      final String? fcmToken = await NotificationService.getToken();

      final response = await http.post(
        Uri.parse('$_backendUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': userCredential.user?.displayName,
          'email': userCredential.user?.email,
          'firebaseToken': idToken,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _handleLoginSuccess(data);
        if (response.statusCode == 201) {
          AnalyticsService.logUserSignUp('google');
        } else {
          AnalyticsService.logUserLogin('google');
        }
      } else {
        await _auth?.signOut();
        await _googleSignIn?.signOut();
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_auth == null) throw Exception("Firebase Auth not initialized");
    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> loginAsGuest() async {
    _isAuthenticated = true;
    _isGuest = true;
    _token = null;
    _role = 'user';
    _user = User(
      id: 'guest_uid',
      name: 'Guest User',
      email: 'guest@riyo.app',
      role: 'user',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
    await prefs.setBool('isGuest', true);
    await prefs.setString('role', _role!);

    notifyListeners();
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> data) async {
    _token = data['token'];
    _role = data['role'];
    _user = User.fromJson(data);
    _isAuthenticated = true;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
    await prefs.setBool('isGuest', false);
    await prefs.setString('token', _token!);
    await prefs.setString('role', _role!);
    await prefs.setString('user', jsonEncode(_user!.toJson()));

    // Asynchronously update analytics
    _updateUserAnalytics();

    notifyListeners();
  }

  Future<void> _updateUserAnalytics() async {
    if (_token == null) return;

    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> deviceData = {};
      String os = 'Unknown';

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceData = {
          'model': webInfo.browserName.toString(),
          'os': 'Web',
          'userAgent': webInfo.userAgent,
          'deviceId': webInfo.vendor,
        };
        os = 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          'model': androidInfo.model,
          'os': 'Android ${androidInfo.version.release}',
          'deviceId': androidInfo.id,
        };
        os = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          'model': iosInfo.utsname.machine,
          'os': 'iOS ${iosInfo.systemVersion}',
          'deviceId': iosInfo.identifierForVendor,
        };
        os = 'iOS';
      }

      // Get IP-based location info (using a free public API for now)
      Map<String, dynamic> locationData = {};
      try {
        final locResponse = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 5));
        if (locResponse.statusCode == 200) {
          final loc = jsonDecode(locResponse.body);
          locationData = {
            'country': loc['country_name'],
            'city': loc['city'],
            'lat': loc['latitude'].toString(),
            'lon': loc['longitude'].toString(),
            'ip': loc['ip'],
          };
        }
      } catch (e) {
        debugPrint('Location fetch error: $e');
      }

      await http.put(
        Uri.parse('$_backendUrl/users/analytics/device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'deviceInfo': {
            'model': deviceData['model'] ?? 'Unknown',
            'os': deviceData['os'] ?? os,
            'deviceId': deviceData['deviceId'] ?? 'Unknown',
            'userAgent': deviceData['userAgent'] ?? 'Mobile App',
            'ip': locationData['ip'] ?? 'Unknown',
          },
          'location': {
            'country': locationData['country'] ?? 'Unknown',
            'city': locationData['city'] ?? 'Unknown',
            'lat': locationData['lat'] ?? '0',
            'lon': locationData['lon'] ?? '0',
          }
        }),
      );
    } catch (e) {
      debugPrint('Error updating user analytics: $e');
    }
  }

  void _handleError(dynamic e) {
    if (e is fb.FirebaseAuthException) {
      // Return the error code for UI to map to specific messages
      throw Exception(e.code);
    }
    if (e is http.ClientException || e.toString().contains('SocketException')) {
      throw Exception('network-request-failed');
    }
    if (e is TimeoutException) {
      throw Exception('timeout');
    }
    throw e;
  }

  Future<void> logout() async {
    await _auth?.signOut();
    await _googleSignIn?.signOut();
    _isAuthenticated = false;
    _isGuest = false;
    _token = null;
    _role = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.setBool('isGuest', false);
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
