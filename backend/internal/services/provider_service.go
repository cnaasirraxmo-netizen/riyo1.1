package services

import (
	"io"
	"net/http"
	"sync"
	"time"
	"github.com/riyobox/backend/internal/extraction"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
)

// CallProviders fetches sources concurrently from all registered providers and processes them through the extraction engine.
func CallProviders(tmdbID int, title string, isTvShow bool, season, episode int) []models.Source {
	var allSources []models.Source
	var mu sync.Mutex
	var wg sync.WaitGroup

	// Fetch embed provider URLs
	var embedProviders []providers.EmbedProvider
	if isTvShow {
		embedProviders = providers.GetTVEmbedProviders()
	} else {
		embedProviders = providers.GetEmbedProviders()
	}

	for _, p := range embedProviders {
		wg.Add(1)
		go func(p providers.EmbedProvider) {
			defer wg.Done()
			var url string
			if isTvShow {
				url = providers.GenerateTVURL(p, tmdbID, season, episode)
			} else {
				url = providers.GenerateMovieURL(p, tmdbID)
			}

			// Fetch the provider HTML and run extraction
			html, err := fetchHTMLContent(url)
			if err == nil {
				// Use the browser-integrated extraction for each provider's root embed URL
				sources := extraction.ExtractAllWithBrowser(url, html)
				for i := range sources {
					sources[i].Provider = p.Name
				}
				mu.Lock()
				allSources = append(allSources, sources...)
				mu.Unlock()
			}
		}(p)
	}

	wg.Wait()

	// Final processing flow
	validated := ValidateSources(allSources)
	ranked := RankSources(validated)

	return ranked
}

func fetchHTMLContent(url string) (string, error) {
	client := &http.Client{Timeout: 15 * time.Second}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")
	req.Header.Set("Referer", url)

	resp, err := client.Do(req)
	if err != nil { return "", err }
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil { return "", err }
	return string(body), nil
}
