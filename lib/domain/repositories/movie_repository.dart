import 'package:riyo/models/movie.dart';

abstract class MovieRepository {
  Future<Map<String, dynamic>> getTrendingMovies({String? genre, bool isFeatured = false, bool forceRefresh = false, String? cursor});
  Future<Map<String, dynamic>> getTopRatedMovies({bool forceRefresh = false, String? cursor});
  Future<Map<String, dynamic>> getNowPlayingMovies({bool forceRefresh = false, String? cursor});
  Future<List<String>> getCategories({bool forceRefresh = false});
  Future<List<Map<String, dynamic>>> getHomeSections({bool forceRefresh = false});
  Future<List<Movie>> getMoviesByGenre(String genre, {bool forceRefresh = false});
}
