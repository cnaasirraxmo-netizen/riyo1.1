package modules

import (
	"context"
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

func (p *UHDMoviesProvider) Search(ctx context.Context, query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	return p.BaseProvider.Search(ctx, query, isTvShow, season, episode)
}
