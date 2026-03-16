package modules

func NewDotMoviesProvider() *GenericProvider {
	return NewGenericProvider("DotMovies", "https://dotmovies.actor")
}
