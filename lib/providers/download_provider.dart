import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riyo/models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadQuality { low, medium, high }

class DownloadProvider with ChangeNotifier {
  final List<Movie> _downloadingMovies = [];
  List<Movie> _downloadedMovies = [];
  final Map<int, CancelToken> _cancelTokens = {};

  // Settings
  DownloadQuality _quality = DownloadQuality.medium;
  bool _wifiOnly = true;
  bool _autoDownloadEpisodes = true;
  bool _autoDownloadRecommendations = true;
  bool _onlyWhenCharging = false;
  bool _autoDeleteAfterWatching = true;
  int _keepDays = 30;

  List<Movie> get downloadingMovies => _downloadingMovies;
  List<Movie> get downloadedMovies => _downloadedMovies;

  DownloadQuality get quality => _quality;
  bool get wifiOnly => _wifiOnly;
  bool get autoDownloadEpisodes => _autoDownloadEpisodes;
  bool get autoDownloadRecommendations => _autoDownloadRecommendations;
  bool get onlyWhenCharging => _onlyWhenCharging;
  bool get autoDeleteAfterWatching => _autoDeleteAfterWatching;
  int get keepDays => _keepDays;

  // Storage stats (Mock)
  double get totalStorageGB => 128.0;
  double get usedStorageGB => 45.2;
  double get downloadsSizeGB => 1.2;

  DownloadProvider() {
    _loadDownloadedMovies();
  }

  Future<void> _loadDownloadedMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final String? moviesJson = prefs.getString('downloaded_movies');
    if (moviesJson != null) {
      final List<dynamic> decoded = jsonDecode(moviesJson);
      _downloadedMovies = decoded.map((item) => Movie.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveDownloadedMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_downloadedMovies.map((m) => m.toJson()).toList());
    await prefs.setString('downloaded_movies', encoded);
  }

  bool isDownloaded(int movieId) {
    return _downloadedMovies.any((m) => m.id == movieId);
  }

  bool isDownloading(int movieId) {
    return _downloadingMovies.any((m) => m.id == movieId);
  }

  double getDownloadProgress(int movieId) {
    final movie = _downloadingMovies.firstWhere((m) => m.id == movieId, orElse: () => Movie(id: 0, title: '', overview: '', posterPath: '', releaseDate: ''));
    return movie.downloadProgress;
  }

  Future<void> startDownload(Movie movie) async {
    if (isDownloaded(movie.id) || isDownloading(movie.id)) return;

    final videoUrl = movie.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) return;

    final movieToDownload = movie.copyWith(isDownloading: true, downloadProgress: 0.0);
    _downloadingMovies.add(movieToDownload);
    notifyListeners();

    final cancelToken = CancelToken();
    _cancelTokens[movie.id] = cancelToken;

    try {
      final directory = await getApplicationDocumentsDirectory();
      String extension = p.extension(videoUrl).split('?').first;
      if (extension.isEmpty) {
        // Try to detect extension from movie sources if available
        if (movie.sources != null && movie.sources!.isNotEmpty) {
          final sUrl = movie.sources!.first.url;
          extension = p.extension(sUrl).split('?').first;
        }
      }
      final fileName = '${movie.id}${extension.isEmpty ? ".mp4" : extension}';
      final downloadDir = Directory(p.join(directory.path, 'downloads'));
      final filePath = p.join(downloadDir.path, fileName);

      // Robust directory creation with error handling
      try {
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      } catch (e) {
        throw FileSystemException("Could not create downloads directory", downloadDir.path, e as dynamic);
      }

      if (videoUrl.contains('.m3u8')) {
        // HLS Downloader logic (Minimal - downloads manifest)
        // For a full HLS downloader, we'd need to parse the manifest and download segments.
        // For now, we'll download the manifest and allow the player to attempt playback.
        final dio = Dio();
        await dio.download(videoUrl, filePath, cancelToken: cancelToken);
      } else {
      final dio = Dio();
      await dio.download(
        videoUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final index = _downloadingMovies.indexWhere((m) => m.id == movie.id);
            if (index != -1) {
              _downloadingMovies[index] = _downloadingMovies[index].copyWith(downloadProgress: progress);
              notifyListeners();
            }
          }
        },
      );
      }

      _downloadingMovies.removeWhere((m) => m.id == movie.id);
      final downloadedMovie = movie.copyWith(
        isDownloaded: true,
        isDownloading: false,
        localPath: filePath,
        fileSize: await _getFileSize(filePath),
      );
      _downloadedMovies.add(downloadedMovie);
      await _saveDownloadedMovies();
      notifyListeners();
    } catch (e) {
      debugPrint('CRITICAL: Download error for ${movie.title}: $e');
      _downloadingMovies.removeWhere((m) => m.id == movie.id);
      notifyListeners();
      // In a real app, we might want to propagate this error to the UI
    } finally {
      _cancelTokens.remove(movie.id);
    }
  }

  Future<String> _getFileSize(String path) async {
    final file = File(path);
    final bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void setQuality(DownloadQuality quality) {
    _quality = quality;
    notifyListeners();
  }

  void setWifiOnly(bool value) {
    _wifiOnly = value;
    notifyListeners();
  }

  void setAutoDownloadEpisodes(bool value) {
    _autoDownloadEpisodes = value;
    notifyListeners();
  }

  void setAutoDownloadRecommendations(bool value) {
    _autoDownloadRecommendations = value;
    notifyListeners();
  }

  void setOnlyWhenCharging(bool value) {
    _onlyWhenCharging = value;
    notifyListeners();
  }

  void setAutoDeleteAfterWatching(bool value) {
    _autoDeleteAfterWatching = value;
    notifyListeners();
  }

  void setKeepDays(int days) {
    _keepDays = days;
    notifyListeners();
  }

  void cancelDownload(int movieId) {
    _cancelTokens[movieId]?.cancel();
    _downloadingMovies.removeWhere((m) => m.id == movieId);
    notifyListeners();
  }

  Future<void> deleteDownload(int movieId) async {
    final movie = _downloadedMovies.firstWhere((m) => m.id == movieId);
    if (movie.localPath != null) {
      final file = File(movie.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _downloadedMovies.removeWhere((m) => m.id == movieId);
    await _saveDownloadedMovies();
    notifyListeners();
  }

  void clearAllDownloads() {
    _downloadedMovies.clear();
    _downloadingMovies.clear();
    notifyListeners();
  }

  Future<void> deleteOldestDownload() async {
    if (_downloadedMovies.isEmpty) return;
    // Assuming the list is ordered by download time (appended at the end)
    // Or we could use a proper timestamp if we had one in the model.
    // Let's use the first one in the list as "oldest".
    final movie = _downloadedMovies.first;
    await deleteDownload(movie.id);
  }

  Future<void> deleteLargestDownload() async {
    if (_downloadedMovies.isEmpty) return;

    Movie? largestMovie;
    double maxBytes = -1;

    for (var movie in _downloadedMovies) {
      if (movie.localPath != null) {
        final file = File(movie.localPath!);
        if (await file.exists()) {
          final size = await file.length();
          if (size > maxBytes) {
            maxBytes = size.toDouble();
            largestMovie = movie;
          }
        }
      }
    }

    if (largestMovie != null) {
      await deleteDownload(largestMovie.id);
    }
  }

  List<Movie> getMoviesSortedBySize() {
    final List<Movie> sorted = List.from(_downloadedMovies);
    // This is asynchronous-ish in reality but we can mock or use cached sizes if they were numeric
    // For now let's just return the list, and handle sorting in the UI if needed
    // or improve the model to store numeric bytes.
    return sorted;
  }
}
