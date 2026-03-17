package services

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
	"github.com/riyobox/backend/scrapers"
)

type VideoExtractor struct {
	client *http.Client
	finder *scrapers.UniversalFinder
}

func NewVideoExtractor() *VideoExtractor {
	return &VideoExtractor{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		finder: scrapers.NewUniversalFinder(),
	}
}

func (e *VideoExtractor) ExtractSources(tmdbID int, title string, isTvShow bool, season, episode int, requestHost string) []models.StreamSource {
	var allSources []models.StreamSource
	var mu sync.Mutex
	var wg sync.WaitGroup

	// --- 1. CONCURRENT SCRAPING WITH SEARCH PROVIDERS ---
	if title != "" {
		newProviders := providers.GetAllProviders()
		for _, p := range newProviders {
			wg.Add(1)
			go func(p providers.Provider) {
				defer wg.Done()
				sources, err := p.Search(title, isTvShow, season, episode)
				if err == nil {
					for _, s := range sources {
						if isValid, ct := e.ValidateLink(s.URL); isValid {
							s.Type = e.DetectType(s.URL, ct)
							mu.Lock()
							allSources = append(allSources, s)
							mu.Unlock()
						}
					}
				}
			}(p)
		}
	}

	// --- 2. CONCURRENT SCRAPING WITH EMBED PROVIDERS ---
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
				s, ep := season, episode
				if s < 1 {
					s = 1
				}
				if ep < 1 {
					ep = 1
				}
				url = providers.GenerateTVURL(p, tmdbID, s, ep)
			} else {
				url = providers.GenerateMovieURL(p, tmdbID)
			}

			// Add the Embed Source
			mu.Lock()
			allSources = append(allSources, models.StreamSource{
				Label:    p.Name + " (Embed)",
				URL:      url,
				Type:     "embed",
				Provider: strings.ToLower(p.Name),
				Quality:  "720p",
			})
			mu.Unlock()

			// Use Universal Finder to discover direct links from embed
			discovered := e.finder.FindSources(url)
			for _, link := range discovered {
				if isValid, ct := e.ValidateLink(link); isValid {
					mu.Lock()
					allSources = append(allSources, models.StreamSource{
						Label:    p.Name + " (Direct)",
						URL:      link,
						Type:     e.DetectType(link, ct),
						Provider: strings.ToLower(p.Name),
						Quality:  e.finder.DetectQuality(link),
					})
					mu.Unlock()
				}
			}
		}(p)
	}

	wg.Wait()
	deduped := e.deduplicateSources(allSources)

	// Convert direct sources to proxy URLs and remove embeds
	var finalSources []models.StreamSource
	baseURL := os.Getenv("API_BASE_URL")
	if baseURL == "" && requestHost != "" {
		scheme := "http"
		if strings.Contains(requestHost, "localhost") {
			scheme = "http"
		} else {
			scheme = "https"
		}
		baseURL = fmt.Sprintf("%s://%s", scheme, requestHost)
	}
	if baseURL == "" {
		baseURL = "http://localhost:8080"
	}

	for _, s := range deduped {
		if s.Type != "embed" {
			encodedURL := base64.URLEncoding.EncodeToString([]byte(s.URL))
			s.URL = fmt.Sprintf("%s/api/v1/stream/%s", baseURL, encodedURL)
			finalSources = append(finalSources, s)
		}
	}

	return e.rankSources(finalSources)
}

func (e *VideoExtractor) rankSources(sources []models.StreamSource) []models.StreamSource {
	// Simple ranking based on quality and provider reliability
	// 4K > 1080p > 720p > 480p > 360p
	qualityMap := map[string]int{
		"4K":    5,
		"1080p": 4,
		"720p":  3,
		"480p":  2,
		"360p":  1,
	}

	// Stability/Reliability heuristic: direct links are better than embeds
	providerRank := func(s models.StreamSource) int {
		if s.Type != "embed" {
			return 10
		}
		return 1
	}

	for i := 0; i < len(sources); i++ {
		for j := i + 1; j < len(sources); j++ {
			scoreI := qualityMap[sources[i].Quality]*10 + providerRank(sources[i])
			scoreJ := qualityMap[sources[j].Quality]*10 + providerRank(sources[j])

			if scoreJ > scoreI {
				sources[i], sources[j] = sources[j], sources[i]
			}
		}
	}

	return sources
}

func (e *VideoExtractor) ValidateLink(url string) (bool, string) {
	if url == "" {
		return false, ""
	}

	// Try HEAD request first
	req, err := http.NewRequest("HEAD", url, nil)
	if err != nil {
		return false, ""
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

	resp, err := e.client.Do(req)
	if err == nil {
		defer resp.Body.Close()
		if resp.StatusCode == http.StatusOK {
			contentType := strings.ToLower(resp.Header.Get("Content-Type"))
			if strings.Contains(contentType, "video/") ||
				strings.Contains(contentType, "application/x-mpegurl") ||
				strings.Contains(contentType, "application/dash+xml") ||
				strings.Contains(contentType, "application/octet-stream") ||
				strings.Contains(contentType, "application/vnd.apple.mpegurl") {
				return true, contentType
			}
		} else if resp.StatusCode == http.StatusMethodNotAllowed || resp.StatusCode == http.StatusForbidden {
			// Some servers block HEAD requests, fallback to GET with range
		} else {
			return false, ""
		}
	}

	// Fallback to GET request with Range header if HEAD fails or is inconclusive
	req, err = http.NewRequest("GET", url, nil)
	if err != nil {
		return false, ""
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
	req.Header.Set("Range", "bytes=0-0")

	resp, err = e.client.Do(req)
	if err != nil {
		return false, ""
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusPartialContent {
		contentType := strings.ToLower(resp.Header.Get("Content-Type"))
		isValid := strings.Contains(contentType, "video/") ||
			strings.Contains(contentType, "application/x-mpegurl") ||
			strings.Contains(contentType, "application/dash+xml") ||
			strings.Contains(contentType, "application/octet-stream") ||
			strings.Contains(contentType, "application/vnd.apple.mpegurl") ||
			resp.StatusCode == http.StatusPartialContent

		if isValid {
			return true, contentType
		}
	}

	return false, ""
}

func (e *VideoExtractor) DetectType(url, contentType string) string {
	if strings.Contains(url, ".m3u8") || strings.Contains(contentType, "mpegurl") {
		return "hls"
	}
	if strings.Contains(url, ".mpd") || strings.Contains(contentType, "dash+xml") {
		return "dash"
	}
	if strings.Contains(url, ".mp4") || strings.Contains(contentType, "video/mp4") || strings.Contains(contentType, "application/octet-stream") {
		return "direct"
	}
	if strings.Contains(contentType, "video/") {
		return "direct"
	}
	return "embed"
}

func (e *VideoExtractor) deduplicateSources(sources []models.StreamSource) []models.StreamSource {
	keys := make(map[string]bool)
	var list []models.StreamSource
	for _, entry := range sources {
		if _, value := keys[entry.URL]; !value {
			keys[entry.URL] = true
			list = append(list, entry)
		}
	}
	return list
}
