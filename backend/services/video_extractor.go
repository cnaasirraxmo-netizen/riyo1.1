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

func (e *VideoExtractor) ExtractSources(tmdbID int, title string, isTvShow bool, season, episode int) []models.StreamSource {
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
			if e.finder.IsValidVideo(link) {
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
			}
		}(p)
	}

	wg.Wait()
	deduped := e.deduplicateSources(allSources)

	// Return raw sources, including embeds as fallback
	return e.rankSources(deduped)
}

func (e *VideoExtractor) rankSources(sources []models.StreamSource) []models.StreamSource {
	// Step 9: Source Ranking (Quality > Provider Reliability > Speed/Type)
	qualityMap := map[string]int{
		"4K":    50,
		"1080p": 40,
		"720p":  30,
		"480p":  20,
		"360p":  10,
	}

	// Direct links (hls, dash, direct) are more reliable than external sources
	typeRank := func(t string) int {
		switch t {
		case "hls":
			return 5
		case "direct":
			return 4
		case "dash":
			return 3
		default:
			return 0
		}
	}

	// Some providers are historically better/faster
	providerReliability := map[string]int{
		"vidsrc":      10,
		"vidlink":     9,
		"superembed":  8,
		"2embed":      7,
		"vidsrcpro":   10,
	}

	for i := 0; i < len(sources); i++ {
		for j := i + 1; j < len(sources); j++ {
			pI := providerReliability[strings.ToLower(sources[i].Provider)]
			pJ := providerReliability[strings.ToLower(sources[j].Provider)]

			scoreI := qualityMap[sources[i].Quality] + typeRank(sources[i].Type) + pI
			scoreJ := qualityMap[sources[j].Quality] + typeRank(sources[j].Type) + pJ

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
