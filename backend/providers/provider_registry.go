package providers

import (
	"github.com/riyobox/backend/providers/modules"
)

func GetAllProviders() []Provider {
	return []Provider{
		modules.NewUHDMoviesProvider(),
		modules.NewProtonMoviesProvider(),
		modules.NewFilmyFlyProvider(),
		modules.NewKatMovieHDProvider(),
		modules.NewDotMoviesProvider(),
		modules.NewMovieBoxProvider(),
		modules.NewMovies4UProvider(),
		modules.NewKmMoviesProvider(),
		modules.NewZeeflizProvider(),
		modules.NewRingzProvider(),
		modules.NewHdHub4uProvider(),
		modules.NewOgomoviesProvider(),
		modules.NewA111477Provider(),
		modules.NewMoviezWapProvider(),
		modules.NewShowBoxProvider(),
		modules.NewRidoMoviesProvider(),
		modules.NewFlixHQProvider(),
		modules.NewPrimeWireProvider(),
		modules.NewHiAnimeProvider(),
		modules.NewAnimetsuProvider(),
		modules.NewTokyoInsiderProvider(),
		modules.NewKissKhProvider(),
		modules.NewRogMoviesProvider(),
		modules.NewTopMoviesProvider(),
		modules.NewGuardaHDProvider(),
		modules.NewJoya9tvProvider(),
	}
}
