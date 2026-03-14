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

	for i, p := range embedProviders {
		var url string
		if isTvShow {
			s := season
			if s < 1 { s = 1 }
			ep := episode
			if ep < 1 { ep = 1 }
			url = providers.GenerateTVURL(p, tmdbID, s, ep)
		} else {
			url = providers.GenerateMovieURL(p, tmdbID)
		}

		// Main server
		allSources = append(allSources, models.StreamSource{
			Label:    p.Name + " Server",
			URL:      url,
			Type:     "embed",
			Provider: strings.ToLower(p.Name),
			Quality:  "1080p",
		})

		// Add a backup/mirror for variety if it's the primary provider
		if i == 0 {
			allSources = append(allSources, models.StreamSource{
				Label:    p.Name + " Mirror 1",
				URL:      url + "&mirror=1", // Hypothetical mirror param
				Type:     "embed",
				Provider: strings.ToLower(p.Name),
				Quality:  "720p",
			})
		}
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
