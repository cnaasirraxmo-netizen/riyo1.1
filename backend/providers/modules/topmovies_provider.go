package modules

func NewTopMoviesProvider() *GenericProvider {
	return NewGenericProvider("TopMovies", "https://topmovies.guru")
}
