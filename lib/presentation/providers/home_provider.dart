import 'package:flutter/material.dart';
import 'package:riyo/domain/repositories/movie_repository.dart';
import 'package:riyo/data/repositories/movie_repository_impl.dart';
import 'package:riyo/models/movie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  final List<String> categories;
  final List<Map<String, dynamic>> sections;
  final bool isLoading;
  final String selectedCategory;
  final List<Movie> featuredMovies;
  final Map<String, List<Movie>> sectionMovies;
  final Map<String, String?> sectionCursors;

  HomeState({
    this.categories = const ["All"],
    this.sections = const [],
    this.isLoading = true,
    this.selectedCategory = "All",
    this.featuredMovies = const [],
    this.sectionMovies = const {},
    this.sectionCursors = const {},
  });

  HomeState copyWith({
    List<String>? categories,
    List<Map<String, dynamic>>? sections,
    bool? isLoading,
    String? selectedCategory,
    List<Movie>? featuredMovies,
    Map<String, List<Movie>>? sectionMovies,
    Map<String, String?>? sectionCursors,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      featuredMovies: featuredMovies ?? this.featuredMovies,
      sectionMovies: sectionMovies ?? this.sectionMovies,
      sectionCursors: sectionCursors ?? this.sectionCursors,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    loadConfig();
    return HomeState(isLoading: true);
  }

  MovieRepository get _repository => ref.read(movieRepositoryProvider);

  Future<void> loadConfig({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final categories = await _repository.getCategories(forceRefresh: forceRefresh);
      final sections = await _repository.getHomeSections(forceRefresh: forceRefresh);
      final featuredRes = await _repository.getTrendingMovies(isFeatured: true, forceRefresh: forceRefresh);

      state = state.copyWith(
        categories: categories,
        sections: sections,
        featuredMovies: List<Movie>.from(featuredRes['movies']),
        isLoading: false,
      );

      for (var sec in sections) {
        _loadSection(sec['title'], sec['type'], genre: sec['genre']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadSection(String title, String type, {String? genre}) async {
    try {
      final res = await _fetchMovies(type, genre: genre);
      final movies = List<Movie>.from(res['movies']);
      final cursor = res['nextCursor'] as String?;

      final Map<String, List<Movie>> newSectionMovies = Map.from(state.sectionMovies);
      final Map<String, String?> newSectionCursors = Map.from(state.sectionCursors);

      newSectionMovies[title] = movies;
      newSectionCursors[title] = cursor;

      state = state.copyWith(
        sectionMovies: newSectionMovies,
        sectionCursors: newSectionCursors,
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _fetchMovies(String type, {String? genre, String? cursor}) async {
    switch (type) {
      case 'trending':
        return _repository.getTrendingMovies(genre: genre, cursor: cursor);
      case 'top_rated':
        return _repository.getTopRatedMovies(cursor: cursor);
      case 'new_releases':
        return _repository.getNowPlayingMovies(cursor: cursor);
      case 'genre':
        return _repository.getTrendingMovies(genre: genre, cursor: cursor);
      default:
        return {'movies': <Movie>[], 'nextCursor': null};
    }
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<List<Movie>> getSectionMovies(String title, String type, {String? genre}) async {
     final res = await _fetchMovies(type, genre: genre);
     return List<Movie>.from(res['movies']);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(() {
  return HomeNotifier();
});
