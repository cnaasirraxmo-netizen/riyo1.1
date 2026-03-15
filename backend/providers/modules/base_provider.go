package modules

import (
	"fmt"
	"regexp"
	"net/url"
	"strings"

	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/scrapers"
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
	searchQuery := query
	if isTvShow {
		searchQuery = fmt.Sprintf("%s S%02dE%02d", query, season, episode)
	}
	searchURL := fmt.Sprintf("%s/?s=%s", p.BaseURL, url.QueryEscape(searchQuery))
	html, err := scrapers.FetchHTML(searchURL)
	if err != nil {
		return nil, err
	}

	// Find the first result link
	re := regexp.MustCompile(fmt.Sprintf(`(?i)<a\s+href=["'](%s/[^"']+)["']`, regexp.QuoteMeta(p.BaseURL)))
	matches := re.FindAllStringSubmatch(html, -1)

	var allSources []models.StreamSource
	for _, m := range matches {
		contentURL := m[1]
		if strings.Contains(contentURL, "/?s=") || contentURL == p.BaseURL+"/" {
			continue
		}

		// Use Universal Finder for comprehensive extraction
		finder := scrapers.NewUniversalFinder()
		discovered := finder.FindSources(contentURL)

		for _, link := range discovered {
			isEmbed := strings.Contains(link, "embed") || strings.Contains(link, "player")
			allSources = append(allSources, models.StreamSource{
				Label:    p.Name,
				URL:      link,
				Type:     p.detectType(link, isEmbed),
				Provider: strings.ToLower(p.Name),
				Quality:  finder.DetectQuality(link),
			})
		}

		if len(allSources) > 0 {
			break // Found sources from the first relevant result
		}
	}

	return allSources, nil
}
