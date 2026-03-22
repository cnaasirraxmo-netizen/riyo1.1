package modules

import (
	"encoding/json"
	"fmt"
	"regexp"
	"net/url"
	"strings"

	"context"
	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/scrapers"
	"time"
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

func (p *BaseProvider) Search(ctx context.Context, query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	// METHOD 9 - PROVIDER RESPONSE CACHE
	cacheKey := fmt.Sprintf("provider_%s_%s_%v_%v_%v", strings.ToLower(p.Name), strings.ReplaceAll(strings.ToLower(query), " ", "_"), isTvShow, season, episode)
	cached, err := cache.GetOrSetCache(cacheKey, cache.ProviderTTL, func() (interface{}, error) {
		return p.searchInternal(ctx, query, isTvShow, season, episode)
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

func (p *BaseProvider) searchInternal(ctx context.Context, query string, isTvShow bool, season, episode int) ([]models.StreamSource, error) {
	// Implement exponential backoff retry for provider search
	var html string
	var err error
	maxRetries := 3

	searchQuery := query
	if isTvShow {
		searchQuery = fmt.Sprintf("%s S%02dE%02d", query, season, episode)
	}
	searchURL := fmt.Sprintf("%s/?s=%s", p.BaseURL, url.QueryEscape(searchQuery))

	for i := 0; i < maxRetries; i++ {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
			html, err = scrapers.FetchHTML(searchURL)
			if err == nil {
				break
			}
			backoff := time.Duration(1<<uint(i)) * 500 * time.Millisecond
			time.Sleep(backoff)
		}
	}

	if err != nil {
		return nil, err
	}

	// Find result links - more flexible regex to handle both absolute and relative links
	// It looks for links that look like content pages (usually avoiding common paths like /category/, /tag/, etc.)
	re := regexp.MustCompile(`(?i)<a\s+[^>]*href=["']([^"']+)["'][^>]*>`)
	matches := re.FindAllStringSubmatch(html, -1)

	var allSources []models.StreamSource
	for _, m := range matches {
		link := m[1]
		var contentURL string

		if strings.HasPrefix(link, "http") {
			if !strings.HasPrefix(link, p.BaseURL) {
				continue
			}
			contentURL = link
		} else if strings.HasPrefix(link, "/") {
			contentURL = p.BaseURL + link
		} else {
			continue
		}

		if strings.Contains(contentURL, "/?s=") || contentURL == p.BaseURL+"/" {
			continue
		}

		// Use Universal Finder for comprehensive extraction
		finder := scrapers.NewUniversalFinder()
		discovered := finder.FindSources(contentURL)

		for _, link := range discovered {
			isEmbed := strings.Contains(link, "embed") || strings.Contains(link, "player")

			// Validate that the link is actually a working video or embed
			// We use a simple check here, full validation happens in VideoExtractor
			if finder.IsValidVideo(link) || isEmbed {
				allSources = append(allSources, models.StreamSource{
					Label:    p.Name,
					URL:      link,
					Type:     p.detectType(link, isEmbed),
					Provider: strings.ToLower(p.Name),
					Quality:  finder.DetectQuality(link),
				})
			}
		}

		if len(allSources) > 0 {
			break // Found sources from the first relevant result
		}
	}

	return allSources, nil
}
