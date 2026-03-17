package extraction

import (
	"regexp"
	"strings"
	"github.com/riyobox/backend/internal/models"
)

var (
	// Regex patterns for video URLs and tags
	videoSrcRe   = regexp.MustCompile(`(?i)<(?:video|source|iframe)[^>]+(?:src|data-src|data-video|data-main)=["'](https?://[^"']*(?:\.mp4|\.m3u8|\.mpd|\.webm|\.mkv)[^"']*)["']`)
	videoURLRe   = regexp.MustCompile(`(?i)https?://[^\s"']+\.(?:m3u8|mp4|mpd|webm|mkv)[^\s"']*`)
)

// ExtractHTML scans raw HTML for direct video streams and manifest files.
func ExtractHTML(html string) []models.Source {
	var sources []models.Source

	// 1. Find sources in HTML tags
	matches := videoSrcRe.FindAllStringSubmatch(html, -1)
	for _, m := range matches {
		if len(m) > 1 {
			url := m[1]
			sources = append(sources, models.Source{
				URL:     url,
				Quality: DetectQuality(url),
				Type:    detectType(url),
			})
		}
	}

	// 2. Scan entire HTML for raw video URLs
	rawMatches := videoURLRe.FindAllString(html, -1)
	for _, url := range rawMatches {
		sources = append(sources, models.Source{
			URL:     url,
			Quality: DetectQuality(url),
			Type:    detectType(url),
		})
	}

	return sources
}

func detectType(url string) string {
	lower := strings.ToLower(url)
	if strings.Contains(lower, ".m3u8") {
		return "m3u8"
	}
	if strings.Contains(lower, ".mpd") {
		return "mpd"
	}
	return "mp4"
}
