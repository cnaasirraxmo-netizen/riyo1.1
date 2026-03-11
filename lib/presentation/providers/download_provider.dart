import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riyo/models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum DownloadQuality { low, medium, high }

class DownloadState {
  final List<Movie> downloadingMovies;
  final List<Movie> downloadedMovies;
  final DownloadQuality quality;
  final bool wifiOnly;
  final bool autoDownloadEpisodes;

  DownloadState({
    this.downloadingMovies = const [],
    this.downloadedMovies = const [],
    this.quality = DownloadQuality.medium,
    this.wifiOnly = true,
    this.autoDownloadEpisodes = true,
  });

  DownloadState copyWith({
    List<Movie>? downloadingMovies,
    List<Movie>? downloadedMovies,
    DownloadQuality? quality,
    bool? wifiOnly,
    bool? autoDownloadEpisodes,
  }) {
    return DownloadState(
      downloadingMovies: downloadingMovies ?? this.downloadingMovies,
      downloadedMovies: downloadedMovies ?? this.downloadedMovies,
      quality: quality ?? this.quality,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      autoDownloadEpisodes: autoDownloadEpisodes ?? this.autoDownloadEpisodes,
    );
  }
}

class DownloadNotifier extends fr.Notifier<DownloadState> {
  final Map<int, CancelToken> _cancelTokens = {};

  @override
  DownloadState build() {
    _loadDownloadedMovies();
    return DownloadState();
  }

  Future<void> _loadDownloadedMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final String? moviesJson = prefs.getString('downloaded_movies');
    if (moviesJson != null) {
      final List<dynamic> decoded = jsonDecode(moviesJson);
      final movies = decoded.map((item) => Movie.fromJson(item)).toList();
      state = state.copyWith(downloadedMovies: movies);
    }
  }

  Future<void> _saveDownloadedMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(state.downloadedMovies.map((m) => m.toJson()).toList());
    await prefs.setString('downloaded_movies', encoded);
  }

  bool isDownloaded(int movieId) {
    return state.downloadedMovies.any((m) => m.id == movieId);
  }

  bool isDownloading(int movieId) {
    return state.downloadingMovies.any((m) => m.id == movieId);
  }

  double getDownloadProgress(int movieId) {
    final movie = state.downloadingMovies.firstWhere(
      (m) => m.id == movieId,
      orElse: () => Movie(id: 0, title: '', overview: '', posterPath: '', releaseDate: '')
    );
    return movie.downloadProgress;
  }

  Future<void> startDownload(Movie movie) async {
    if (isDownloaded(movie.id) || isDownloading(movie.id)) return;

    final videoUrl = movie.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) return;

    final movieToDownload = movie.copyWith(isDownloading: true, downloadProgress: 0.0);
    state = state.copyWith(downloadingMovies: [...state.downloadingMovies, movieToDownload]);

    final cancelToken = CancelToken();
    _cancelTokens[movie.id] = cancelToken;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = p.extension(videoUrl).split('?').first;
      final fileName = '${movie.id}${extension.isEmpty ? ".mp4" : extension}';
      final filePath = p.join(directory.path, 'downloads', fileName);

      await Directory(p.dirname(filePath)).create(recursive: true);

      final dio = Dio();
      await dio.download(
        videoUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final updatedDownloading = state.downloadingMovies.map((m) {
              if (m.id == movie.id) {
                return m.copyWith(downloadProgress: progress);
              }
              return m;
            }).toList();
            state = state.copyWith(downloadingMovies: updatedDownloading);
          }
        },
      );

      final downloadedMovie = movie.copyWith(
        isDownloaded: true,
        isDownloading: false,
        localPath: filePath,
        fileSize: await _getFileSize(filePath),
      );

      state = state.copyWith(
        downloadingMovies: state.downloadingMovies.where((m) => m.id != movie.id).toList(),
        downloadedMovies: [...state.downloadedMovies, downloadedMovie],
      );
      await _saveDownloadedMovies();
    } catch (e) {
      state = state.copyWith(
        downloadingMovies: state.downloadingMovies.where((m) => m.id != movie.id).toList(),
      );
    } finally {
      _cancelTokens.remove(movie.id);
    }
  }

  Future<String> _getFileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return '0 MB';
    final bytes = await file.length();
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void cancelDownload(int movieId) {
    _cancelTokens[movieId]?.cancel();
    state = state.copyWith(
      downloadingMovies: state.downloadingMovies.where((m) => m.id != movieId).toList(),
    );
  }

  Future<void> deleteDownload(int movieId) async {
    final movie = state.downloadedMovies.firstWhere((m) => m.id == movieId);
    if (movie.localPath != null) {
      final file = File(movie.localPath!);
      if (await file.exists()) await file.delete();
    }
    state = state.copyWith(
      downloadedMovies: state.downloadedMovies.where((m) => m.id != movieId).toList(),
    );
    await _saveDownloadedMovies();
  }

  void clearAllDownloads() async {
     for (var m in state.downloadedMovies) {
        if (m.localPath != null) {
          final file = File(m.localPath!);
          if (await file.exists()) await file.delete();
        }
     }
     state = state.copyWith(downloadedMovies: []);
     await _saveDownloadedMovies();
  }
}

final downloadProvider = fr.NotifierProvider<DownloadNotifier, DownloadState>(() {
  return DownloadNotifier();
});
