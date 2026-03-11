import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:riyo/data/cache/schemas.dart';
import 'package:riyo/models/movie.dart';

class CacheService {
  static const String movieBoxName = 'movies_cache';
  static const String categoryBoxName = 'categories_cache';
  static const String sectionBoxName = 'sections_cache';
  static const String playbackBoxName = 'playback_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MovieCacheAdapter());
    Hive.registerAdapter(CategoryCacheAdapter());
    Hive.registerAdapter(HomeSectionCacheAdapter());
    Hive.registerAdapter(PlaybackProgressCacheAdapter());

    await Hive.openBox<MovieCache>(movieBoxName);
    await Hive.openBox<CategoryCache>(categoryBoxName);
    await Hive.openBox<HomeSectionCache>(sectionBoxName);
    await Hive.openBox<PlaybackProgressCache>(playbackBoxName);
  }

  // Movies
  Future<void> cacheMovies(List<Movie> movies) async {
    final box = Hive.box<MovieCache>(movieBoxName);
    final now = DateTime.now();
    for (var movie in movies) {
      final id = movie.backendId ?? movie.id.toString();
      await box.put(
        id,
        MovieCache(
          id: id,
          title: movie.title,
          overview: movie.overview,
          posterPath: movie.posterPath,
          backdropPath: movie.backdropPath,
          releaseDate: movie.releaseDate,
          voteAverage: movie.voteAverage,
          runtime: movie.runtime,
          genres: movie.genres,
          isTvShow: movie.isTvShow,
          contentType: movie.contentType,
          cachedAt: now,
        ),
      );
    }
  }

  List<Movie> getCachedMovies(List<String> ids) {
    final box = Hive.box<MovieCache>(movieBoxName);
    return ids
        .map((id) => box.get(id))
        .where((m) => m != null)
        .map((m) => Movie(
              id: m!.id.hashCode,
              backendId: m.id,
              title: m.title,
              overview: m.overview,
              posterPath: m.posterPath,
              backdropPath: m.backdropPath,
              releaseDate: m.releaseDate,
              voteAverage: m.voteAverage,
              runtime: m.runtime,
              genres: m.genres,
              isTvShow: m.isTvShow,
              contentType: m.contentType,
            ))
        .toList();
  }

  // Categories
  Future<void> cacheCategories(List<String> categories) async {
    final box = Hive.box<CategoryCache>(categoryBoxName);
    final now = DateTime.now();
    await box.clear();
    for (var cat in categories) {
      await box.add(CategoryCache(name: cat, cachedAt: now));
    }
  }

  List<String> getCachedCategories() {
    final box = Hive.box<CategoryCache>(categoryBoxName);
    return box.values.map((c) => c.name).toList();
  }

  // Home Sections
  Future<void> cacheHomeSection(String title, String type, String? genre, List<Movie> movies) async {
    final box = Hive.box<HomeSectionCache>(sectionBoxName);
    final movieIds = movies.map((m) => m.backendId ?? m.id.toString()).toList();
    await box.put(
      title,
      HomeSectionCache(
        title: title,
        type: type,
        genre: genre,
        movieIds: movieIds,
        cachedAt: DateTime.now(),
      ),
    );
    await cacheMovies(movies);
  }

  HomeSectionCache? getCachedSection(String title) {
    return Hive.box<HomeSectionCache>(sectionBoxName).get(title);
  }

  // Playback Progress
  Future<void> savePlaybackProgress(String movieId, int position, int duration) async {
    final box = Hive.box<PlaybackProgressCache>(playbackBoxName);
    await box.put(
      movieId,
      PlaybackProgressCache(
        movieId: movieId,
        positionSeconds: position,
        durationSeconds: duration,
        lastWatched: DateTime.now(),
      ),
    );
  }

  PlaybackProgressCache? getPlaybackProgress(String movieId) {
    return Hive.box<PlaybackProgressCache>(playbackBoxName).get(movieId);
  }

  List<PlaybackProgressCache> getAllRecentActivity() {
    final box = Hive.box<PlaybackProgressCache>(playbackBoxName);
    final list = box.values.toList();
    list.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    return list;
  }

  bool isCacheExpired(DateTime cachedAt, Duration duration) {
    return DateTime.now().difference(cachedAt) > duration;
  }
}
