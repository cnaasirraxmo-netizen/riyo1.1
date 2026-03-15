package modules

import (
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

func (p *GenericProvider) Search(query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	return p.BaseProvider.Search(query, isTvShow, season, episode)
}
