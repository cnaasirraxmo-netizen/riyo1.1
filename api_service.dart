List<Movie> _getMockMovies() {
  return [
    Movie(id: 1, title: 'Movie 1', year: 2021),
    Movie(id: 2, title: 'Movie 2', year: 2022),
    Movie(id: 3, title: 'Movie 3', year: 2023),
    // Add more movies as needed.
  ];
}

Movie getMovieDetails(int id) {
  if (id < 1 || id > _getMockMovies().length) {
    throw Exception('Movie ID out of bounds');
  }
  return _getMockMovies()[id - 1];
}