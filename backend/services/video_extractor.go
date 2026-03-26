package services

import (
	"context"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
	"github.com/riyobox/backend/scrapers"
)

// VideoExtractor orchestrates the entire scraping pipeline (Steps 2-10).
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

// ExtractSources implements the core discovery work (Step 5).
func (e *VideoExtractor) ExtractSources(tmdbID int, title string, isTvShow bool, season, episode int) []models.StreamSource {
	var allSources []models.StreamSource
	var mu sync.Mutex
	var wg sync.WaitGroup

	log.Printf("[EXTRACTOR] Starting extraction for TMDb: %d, Title: %s", tmdbID, title)

	// --- STEP 4: REQUEST EMBED PAGE ---
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
				if s < 1 { s = 1 }
				if ep < 1 { ep = 1 }
				url = providers.GenerateTVURL(p, tmdbID, s, ep)
			} else {
				url = providers.GenerateMovieURL(p, tmdbID)
			}

			// --- STEP 5: UNIVERSAL VIDEO FINDER ---
			// Scraper sends requests to embed pages and searches for streaming links.
			discovered := e.finder.FindSources(url)
			for _, link := range discovered {
				// --- STEP 7: SOURCE VALIDATION ---
				if isValid, ct := e.ValidateLink(link); isValid {
					mu.Lock()
					allSources = append(allSources, models.StreamSource{
						Label:    p.Name + " (Direct)",
						URL:      link,
						Type:     e.DetectType(link, ct),
						Provider: strings.ToLower(p.Name),
						// --- STEP 8: QUALITY DETECTION ---
						Quality:  e.finder.DetectQuality(link),
					})
					mu.Unlock()
				}
			}
		}(p)
	}

	// --- OPTIONAL: SEARCH PROVIDERS ---
	if title != "" {
		newProviders := providers.GetAllProviders()
		for _, p := range newProviders {
			wg.Add(1)
			go func(p providers.Provider) {
				defer wg.Done()
				ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
				defer cancel()
				sources, err := p.Search(ctx, title, isTvShow, season, episode)
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

	wg.Wait()

	// --- STEP 6: MERGE SOURCES & REMOVE DUPLICATES ---
	deduped := e.deduplicateSources(allSources)

	// --- STEP 9: SOURCE RANKING ---
	ranked := e.rankSources(deduped)

	log.Printf("[EXTRACTOR] Extraction complete. Found %d unique sources for %d", len(ranked), tmdbID)
	return ranked
}

// rankSources implements STEP 9 — SOURCE RANKING.
func (e *VideoExtractor) rankSources(sources []models.StreamSource) []models.StreamSource {
	qualityMap := map[string]int{
		"4K":    50,
		"1080p": 40,
		"720p":  30,
		"480p":  20,
		"360p":  10,
	}

	typeRank := func(t string) int {
		switch t {
		case "hls":    return 10
		case "direct": return 8
		case "dash":   return 7
		case "embed":  return 1
		default:       return 0
		}
	}

	providerReliability := map[string]int{
		"vidsrc":     15,
		"vidlink":    14,
		"superembed": 12,
		"2embed":     10,
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

// ValidateLink implements STEP 7 — SOURCE VALIDATION using HEAD/GET requests.
func (e *VideoExtractor) ValidateLink(url string) (bool, string) {
	if url == "" {
		return false, ""
	}

	if strings.Contains(url, "vidsrc.to") || strings.Contains(url, "2embed.cc") || strings.Contains(url, "multiembed.mov") {
		return true, "text/html"
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		log.Printf("[VALIDATOR] Error creating request for %s: %v", url, err)
		return false, ""
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
	req.Header.Set("Range", "bytes=0-0")

	resp, err := e.client.Do(req)
	if err != nil {
		log.Printf("[VALIDATOR] Connection error for %s: %v", url, err)
		return false, ""
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusPartialContent {
		contentType := strings.ToLower(resp.Header.Get("Content-Type"))

		isValid := strings.Contains(contentType, "video/") ||
			strings.Contains(contentType, "mpegurl") ||
			strings.Contains(contentType, "dash+xml") ||
			strings.Contains(contentType, "application/octet-stream") ||
			resp.StatusCode == http.StatusPartialContent

		if !isValid {
			log.Printf("[VALIDATOR] Invalid Content-Type: %s for %s", contentType, url)
		}

		return isValid, contentType
	}

	log.Printf("[VALIDATOR] Status Error: %d for %s", resp.StatusCode, url)
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
