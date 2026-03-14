package services

import (
	"net/http"
	"strings"

	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
)

type VideoExtractor struct{}

func NewVideoExtractor() *VideoExtractor {
	return &VideoExtractor{}
}

func (e *VideoExtractor) ExtractSources(tmdbID int, isTvShow bool, season, episode int) []models.StreamSource {
	var embedProviders []providers.EmbedProvider
	if isTvShow {
		embedProviders = providers.GetTVEmbedProviders()
	} else {
		embedProviders = providers.GetEmbedProviders()
	}

	var allSources []models.StreamSource

	for _, p := range embedProviders {
		var url string
		if isTvShow {
			// Ensure season and episode are at least 1
			s := season
			if s < 1 { s = 1 }
			ep := episode
			if ep < 1 { ep = 1 }
			url = providers.GenerateTVURL(p, tmdbID, s, ep)
		} else {
			url = providers.GenerateMovieURL(p, tmdbID)
		}

		allSources = append(allSources, models.StreamSource{
			Label:    p.Name,
			URL:      url,
			Type:     "embed",
			Provider: strings.ToLower(p.Name),
			Quality:  "720p", // Default for embeds
		})
	}

	return allSources
}

func (e *VideoExtractor) ValidateLink(url string) bool {
	resp, err := http.Head(url)
	if err != nil {
		return false
	}
	return resp.StatusCode == http.StatusOK
}

func (e *VideoExtractor) DetectType(url string) string {
	if strings.Contains(url, ".m3u8") {
		return "hls"
	}
	if strings.Contains(url, ".mp4") {
		return "direct"
	}
	return "embed"
}
