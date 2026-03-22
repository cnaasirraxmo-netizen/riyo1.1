package providers

import (
	"context"
	"github.com/riyobox/backend/internal/models"
)

type Provider interface {
	GetName() string
	Search(ctx context.Context, query string, isTvShow bool, season, episode int) ([]models.StreamSource, error)
}
