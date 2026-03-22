package modules

import (
	"context"
	"github.com/riyobox/backend/internal/models"
)

type GenericProvider struct {
	BaseProvider
}

func NewGenericProvider(name, baseURL string) *GenericProvider {
	return &GenericProvider{
		BaseProvider: BaseProvider{
			Name:    name,
			BaseURL: baseURL,
		},
	}
}

func (p *GenericProvider) Search(ctx context.Context, query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	return p.BaseProvider.Search(ctx, query, isTvShow, season, episode)
}
