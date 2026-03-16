package modules

func NewRogMoviesProvider() *GenericProvider {
	return NewGenericProvider("RogMovies", "https://rogmovies.info")
}
