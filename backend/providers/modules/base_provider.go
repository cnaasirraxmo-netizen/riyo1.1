package modules

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strings"
	"time"

	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/extraction"
	"github.com/riyobox/backend/internal/models"
)

type BaseProvider struct {
	Name    string
	BaseURL string
}

func (p *BaseProvider) GetName() string {
	return p.Name
}

func (p *BaseProvider) detectType(url string, isEmbed bool) string {
	if isEmbed {
		return "embed"
	}
	if strings.Contains(url, ".m3u8") {
		return "hls"
	}
	if strings.Contains(url, ".mpd") {
		return "dash"
	}
	return "direct"
}

func (p *BaseProvider) Search(query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	// METHOD 9 - PROVIDER RESPONSE CACHE
	cacheKey := fmt.Sprintf("provider_%s_%s_%v_%v_%v", strings.ToLower(p.Name), strings.ReplaceAll(strings.ToLower(query), " ", "_"), isTvShow, season, episode)
	cached, err := cache.GetOrSetCache(cacheKey, cache.ProviderTTL, func() (interface{}, error) {
		return p.searchInternal(query, isTvShow, season, episode)
	})

	if err != nil {
		return nil, err
	}

	// Type assertion back to models.StreamSource list
	// Note: JSON deserialization might return map[string]interface{} for structs
	// We handle conversion in handlers or use a more specific wrapper if needed.
	// For now, let's keep it simple as the requirement asks for GetOrSetCache returning interface{}

	if sources, ok := cached.([]models.StreamSource); ok {
		return sources, nil
	}

	// Handle case where it's generic data from Redis
	var sources []models.StreamSource
	data, _ := json.Marshal(cached)
	json.Unmarshal(data, &sources)
	return sources, nil
}

func (p *BaseProvider) searchInternal(query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	searchQuery := query
	if isTvShow {
		searchQuery = fmt.Sprintf("%s S%02dE%02d", query, season, episode)
	}
	searchURL := fmt.Sprintf("%s/?s=%s", p.BaseURL, url.QueryEscape(searchQuery))

	// Use the unified extraction's fetch helper
	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Get(searchURL)
	if err != nil { return nil, err }
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	html := string(body)

	// Find the first result link
	re := regexp.MustCompile(fmt.Sprintf(`(?i)<a\s+href=["'](%s/[^"']+)["']`, regexp.QuoteMeta(p.BaseURL)))
	matches := re.FindAllStringSubmatch(html, -1)

	var allSources []models.StreamSource
	for _, m := range matches {
		contentURL := m[1]
		if strings.Contains(contentURL, "/?s=") || contentURL == p.BaseURL+"/" {
			continue
		}

		// Fetch content HTML and use unified extraction for comprehensive discovery
		resp, err := client.Get(contentURL)
		if err != nil { continue }
		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		discovered := extraction.ExtractAll(string(body))

		for _, s := range discovered {
			allSources = append(allSources, models.StreamSource{
				Label:    p.Name,
				URL:      s.URL,
				Type:     s.Type,
				Provider: strings.ToLower(p.Name),
				Quality:  s.Quality,
			})
		}

		if len(allSources) > 0 {
			break // Found sources from the first relevant result
		}
	}

	return allSources, nil
}
