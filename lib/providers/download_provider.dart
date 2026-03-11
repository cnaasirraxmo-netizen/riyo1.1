import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/download_provider.dart' as riverpod;
import 'package:riyo/models/movie.dart';

class DownloadProvider extends ChangeNotifier {
  final Ref ref;

  DownloadProvider(this.ref) {
    ref.listen(riverpod.downloadProvider, (previous, next) {
      notifyListeners();
    });
  }

  bool isDownloaded(int movieId) => ref.read(riverpod.downloadProvider.notifier).isDownloaded(movieId);
  bool isDownloading(int movieId) => ref.read(riverpod.downloadProvider.notifier).isDownloading(movieId);
  double getDownloadProgress(int movieId) => ref.read(riverpod.downloadProvider.notifier).getDownloadProgress(movieId);

  void startDownload(Movie movie) => ref.read(riverpod.downloadProvider.notifier).startDownload(movie);
  void cancelDownload(int id) => ref.read(riverpod.downloadProvider.notifier).cancelDownload(id);
  void deleteDownload(int id) => ref.read(riverpod.downloadProvider.notifier).deleteDownload(id);
  void clearAllDownloads() => ref.read(riverpod.downloadProvider.notifier).clearAllDownloads();

  List<Movie> get downloadedMovies => ref.read(riverpod.downloadProvider).downloadedMovies;
  List<Movie> get downloadingMovies => ref.read(riverpod.downloadProvider).downloadingMovies;
  bool get autoDownloadEpisodes => ref.read(riverpod.downloadProvider).autoDownloadEpisodes;

  Future<void> deleteOldestDownload() async {}
  Future<void> deleteLargestDownload() async {}
}
