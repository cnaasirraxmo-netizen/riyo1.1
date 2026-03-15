package modules

import (
	"github.com/riyobox/backend/internal/models"
)

type UHDMoviesProvider struct {
	BaseProvider
}

func NewUHDMoviesProvider() *UHDMoviesProvider {
	return &UHDMoviesProvider{
		BaseProvider: BaseProvider{
			Name:    "UHDMovies",
			BaseURL: "https://uhdmovies.vip",
		},
	}
}

func (p *UHDMoviesProvider) Search(query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	return p.BaseProvider.Search(query, isTvShow, season, episode)
}
