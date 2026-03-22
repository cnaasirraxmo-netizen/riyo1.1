import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riyo/core/constants.dart';
import 'package:riyo/models/movie.dart';

class MediaResource {
  final String url;
  final String type;

  MediaResource({required this.url, required this.type});

  factory MediaResource.fromJson(Map<String, dynamic> json) {
    return MediaResource(
      url: json['url'],
      type: json['type'],
    );
  }
}

class MediaSnifferProvider with ChangeNotifier {
  bool _isLoading = false;
  List<MediaResource> _detectedResources = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<MediaResource> get detectedResources => _detectedResources;
  String? get error => _error;

  Future<void> sniffUrl(String url) async {
    _isLoading = true;
    _error = null;
    _detectedResources = [];
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/v1/extract'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url, 'headless': true}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _detectedResources = data.map((json) => MediaResource.fromJson(json)).toList();
      } else {
        _error = 'Failed to extract media: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _detectedResources = [];
    _error = null;
    notifyListeners();
  }
}
