import 'dart:convert';

class Movie {
  final List<String> genres;

  Movie({required this.genres});

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Safe type casting for genres
    var genresFromJson = json['genres'];
    List<String> genresList = genresFromJson is List ? List<String>.from(genresFromJson) : [];

    return Movie(
      genres: genresList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'genres': genres,
    };
  }
}