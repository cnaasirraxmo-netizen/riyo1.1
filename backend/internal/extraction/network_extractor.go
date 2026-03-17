package extraction

import (
	"regexp"
	"github.com/riyobox/backend/internal/models"
)

var (
	// Regex for network endpoints and API discovery (manifests, API responses)
	networkURLRe = regexp.MustCompile(`(?i)["'](https?://[^"']*(?:\.m3u8|\.mp4|\.mpd|\/api\/v\d\/|\/ajax\/|\/get_source\/|\/playlist\/)[^"']*)["']`)
)

// ExtractNetwork scans for hidden manifest URLs and API endpoints in raw strings.
func ExtractNetwork(html string) []models.Source {
	var sources []models.Source
	matches := networkURLRe.FindAllStringSubmatch(html, -1)

	for _, m := range matches {
		if len(m) > 1 {
			url := m[1]
			// Check if it's already a direct video URL or manifest
			if IsVideoURL(url) {
				sources = append(sources, models.Source{
					URL:     url,
					Quality: DetectQuality(url),
					Type:    detectType(url),
				})
			}
		}
	}

	return sources
}
