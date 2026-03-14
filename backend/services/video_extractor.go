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
			url = providers.GenerateTVURL(p, tmdbID, season, episode)
		} else {
			url = providers.GenerateMovieURL(p, tmdbID)
		}

		// Simplified: For now, we return the embed URL as a source
		// In a real scenario, we would scrape it to get direct links
		allSources = append(allSources, models.StreamSource{
			Label:    p.Name,
			URL:      url,
			Type:     "embed",
			Provider: strings.ToLower(p.Name),
		})

		// Example of scraping (commented out for now as it might be slow during API request)
		/*
		html, err := scrapers.FetchHTML(url)
		if err == nil {
			directSources := scrapers.ExtractVideoSources(html)
			for _, ds := range directSources {
				if e.ValidateLink(ds) {
					allSources = append(allSources, models.StreamSource{
						Label: p.Name + " Direct",
						URL: ds,
						Type: e.DetectType(ds),
						Provider: strings.ToLower(p.Name),
					})
				}
			}
		}
		*/
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
