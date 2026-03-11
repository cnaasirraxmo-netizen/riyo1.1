import 'package:flutter/material.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';

class SystemConfigProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _config = {};
  bool _isLoading = false;

  Map<String, dynamic> get config => _config;
  bool get isLoading => _isLoading;

  Future<void> fetchConfig() async {
    _isLoading = true;
    notifyListeners();
    try {
    } catch (e) {
      debugPrint('Error fetching system config: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
