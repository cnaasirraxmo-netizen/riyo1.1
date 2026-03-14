package services

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
	"github.com/riyobox/backend/scrapers"
)

type VideoExtractor struct {
	client *http.Client
}

func NewVideoExtractor() *VideoExtractor {
	return &VideoExtractor{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (e *VideoExtractor) ExtractSources(tmdbID int, isTvShow bool, season, episode int) []models.StreamSource {
	var embedProviders []providers.EmbedProvider
	if isTvShow {
		embedProviders = providers.GetTVEmbedProviders()
	} else {
		embedProviders = providers.GetEmbedProviders()
	}

	var allSources []models.StreamSource
	var mu sync.Mutex
	var wg sync.WaitGroup

	for _, p := range embedProviders {
		wg.Add(1)
		go func(p providers.EmbedProvider) {
			defer wg.Done()

			var url string
			if isTvShow {
				s, ep := season, episode
				if s < 1 { s = 1 }
				if ep < 1 { ep = 1 }
				url = providers.GenerateTVURL(p, tmdbID, s, ep)
			} else {
				url = providers.GenerateMovieURL(p, tmdbID)
			}

			// 1. Add the Embed Source (Reliable fallback)
			mu.Lock()
			allSources = append(allSources, models.StreamSource{
				Label:    p.Name + " (Embed)",
				URL:      url,
				Type:     "embed",
				Provider: strings.ToLower(p.Name),
				Quality:  "720p",
			})
			mu.Unlock()

			// 2. Try to extract direct .mp4/.m3u8 links (High Quality)
			html, err := scrapers.FetchHTML(url)
			if err == nil {
				directLinks := scrapers.ExtractVideoSources(html)
				for _, link := range directLinks {
					if e.ValidateLink(link) {
						mu.Lock()
						allSources = append(allSources, models.StreamSource{
							Label:    p.Name + " (Direct)",
							URL:      link,
							Type:     e.DetectType(link),
							Provider: strings.ToLower(p.Name),
							Quality:  "1080p",
						})
						mu.Unlock()
					}
				}
			}
		}(p)
	}

	wg.Wait()
	return allSources
}

func (e *VideoExtractor) ValidateLink(url string) bool {
	req, err := http.NewRequest("HEAD", url, nil)
	if err != nil {
		return false
	}

	resp, err := e.client.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

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
