import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/data/cache/cache_service.dart';
import 'package:riyo/domain/repositories/movie_repository.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/presentation/providers/auth_provider.dart';
import 'package:riyo/main.dart';

class MovieRepositoryImpl implements MovieRepository {
  final ApiService _apiService;
  final CacheService _cacheService;
  final Ref _ref;

  MovieRepositoryImpl(this._apiService, this._cacheService, this._ref);

  String? get _token => _ref.read(authProvider).token;

  @override
  Future<Map<String, dynamic>> getTrendingMovies({String? genre, bool isFeatured = false, bool forceRefresh = false, String? cursor}) async {
    final cacheKey = 'trending_${genre}_$isFeatured';

    if (cursor == null) {
      final cached = _cacheService.getCachedSection(cacheKey);
      if (cached != null) {
        final cachedMovies = _cacheService.getCachedMovies(cached.movieIds);
        if (!_cacheService.isCacheExpired(cached.cachedAt, const Duration(minutes: 10)) && !forceRefresh) {
          return {'movies': cachedMovies, 'nextCursor': cached.movieIds.length >= 20 ? cached.movieIds.last : null};
        }

        _apiService.getTrendingMovies(token: _token, genre: genre, isFeatured: isFeatured).then((res) {
          _cacheService.cacheHomeSection(cacheKey, 'trending', genre, List<Movie>.from(res['movies']));
        }).catchError((_) {});

        return {'movies': cachedMovies, 'nextCursor': cached.movieIds.length >= 20 ? cached.movieIds.last : null};
      }
    }

    final res = await _apiService.getTrendingMovies(token: _token, genre: genre, isFeatured: isFeatured, cursor: cursor);
    if (cursor == null) {
      await _cacheService.cacheHomeSection(cacheKey, 'trending', genre, List<Movie>.from(res['movies']));
    }
    return res;
  }

  @override
  Future<Map<String, dynamic>> getTopRatedMovies({bool forceRefresh = false, String? cursor}) async {
    const cacheKey = 'top_rated';
    if (cursor == null) {
      final cached = _cacheService.getCachedSection(cacheKey);
      if (cached != null) {
        final cachedMovies = _cacheService.getCachedMovies(cached.movieIds);
        if (!_cacheService.isCacheExpired(cached.cachedAt, const Duration(minutes: 60)) && !forceRefresh) {
          return {'movies': cachedMovies, 'nextCursor': cached.movieIds.length >= 20 ? cached.movieIds.last : null};
        }
        _apiService.getTopRatedMovies(token: _token).then((res) {
          _cacheService.cacheHomeSection(cacheKey, 'top_rated', null, List<Movie>.from(res['movies']));
        }).catchError((_) {});
        return {'movies': cachedMovies, 'nextCursor': cached.movieIds.length >= 20 ? cached.movieIds.last : null};
      }
    }

    final res = await _apiService.getTopRatedMovies(token: _token, cursor: cursor);
    if (cursor == null) {
      await _cacheService.cacheHomeSection(cacheKey, 'top_rated', null, List<Movie>.from(res['movies']));
    }
    return res;
  }

  @override
  Future<Map<String, dynamic>> getNowPlayingMovies({bool forceRefresh = false, String? cursor}) async {
    const cacheKey = 'now_playing';
    if (cursor == null) {
      final cached = _cacheService.getCachedSection(cacheKey);
      if (cached != null) {
        final cachedMovies = _cacheService.getCachedMovies(cached.movieIds);
        if (!_cacheService.isCacheExpired(cached.cachedAt, const Duration(minutes: 60)) && !forceRefresh) {
          return {'movies': cachedMovies, 'nextCursor': cached.movieIds.length >= 20 ? cached.movieIds.last : null};
        }
        _apiService.getNowPlayingMovies(token: _token).then((res) {
          _cacheService.cacheHomeSection(cacheKey, 'new_releases', null, List<Movie>.from(res['movies']));
        }).catchError((_) {});
        return {'movies': cachedMovies, 'nextCursor': cached.movieIds.length >= 20 ? cached.movieIds.last : null};
      }
    }

    final res = await _apiService.getNowPlayingMovies(token: _token, cursor: cursor);
    if (cursor == null) {
      await _cacheService.cacheHomeSection(cacheKey, 'new_releases', null, List<Movie>.from(res['movies']));
    }
    return res;
  }

  @override
  Future<List<String>> getCategories({bool forceRefresh = false}) async {
    final cached = _cacheService.getCachedCategories();
    if (cached.isNotEmpty && !forceRefresh) {
      _apiService.getHeaderCategories().then((categories) {
        _cacheService.cacheCategories(categories);
      }).catchError((_) {});
      return cached;
    }

    final categories = await _apiService.getHeaderCategories();
    await _cacheService.cacheCategories(categories);
    return categories;
  }

  @override
  Future<List<Map<String, dynamic>>> getHomeSections({bool forceRefresh = false}) async {
    return _apiService.getHomeSections();
  }

  @override
  Future<List<Movie>> getMoviesByGenre(String genre, {bool forceRefresh = false}) async {
    final res = await getTrendingMovies(genre: genre, forceRefresh: forceRefresh);
    return List<Movie>.from(res['movies']);
  }
}

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(
    ApiService(),
    ref.read(cacheServiceProvider),
    ref,
  );
});
