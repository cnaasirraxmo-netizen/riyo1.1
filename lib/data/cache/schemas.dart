import 'package:hive_ce/hive_ce.dart';

part 'schemas.g.dart';

@HiveType(typeId: 0)
class MovieCache extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String overview;

  @HiveField(3)
  final String posterPath;

  @HiveField(4)
  final String? backdropPath;

  @HiveField(5)
  final String releaseDate;

  @HiveField(6)
  final double voteAverage;

  @HiveField(7)
  final int? runtime;

  @HiveField(8)
  final List<String>? genres;

  @HiveField(9)
  final bool isTvShow;

  @HiveField(10)
  final String contentType;

  @HiveField(11)
  final DateTime cachedAt;

  MovieCache({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    this.runtime,
    this.genres,
    required this.isTvShow,
    required this.contentType,
    required this.cachedAt,
  });
}

@HiveType(typeId: 3)
class PlaybackProgressCache extends HiveObject {
  @HiveField(0)
  final String movieId;

  @HiveField(1)
  final int positionSeconds;

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final DateTime lastWatched;

  PlaybackProgressCache({
    required this.movieId,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.lastWatched,
  });
}

@HiveType(typeId: 1)
class CategoryCache extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final DateTime cachedAt;

  CategoryCache({required this.name, required this.cachedAt});
}

@HiveType(typeId: 2)
class HomeSectionCache extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String? genre;

  @HiveField(3)
  final List<String> movieIds;

  @HiveField(4)
  final DateTime cachedAt;

  HomeSectionCache({
    required this.title,
    required this.type,
    this.genre,
    required this.movieIds,
    required this.cachedAt,
  });
}
