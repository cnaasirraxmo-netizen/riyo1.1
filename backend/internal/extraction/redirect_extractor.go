package extraction

import (
	"net/http"
	"regexp"
	"time"
	"github.com/riyobox/backend/internal/models"
)

var (
	// Regex for links that likely lead to a video after redirect
	redirectPatternRe = regexp.MustCompile(`(?i)href=["'](https?://[^"']*(?:redirect|go|out|visit|link|short|url|to|play|player|embed|v|f|s|download|get|stream|api|ajax)[^"']*)["']`)
)

// ExtractRedirects identifies and follows potential redirect links to discover video URLs.
func ExtractRedirects(html string) []models.Source {
	var sources []models.Source
	matches := redirectPatternRe.FindAllStringSubmatch(html, -1)

	client := &http.Client{
		Timeout: 10 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return http.ErrUseLastResponse
			}
			return nil
		},
	}

	uniqueURLs := make(map[string]bool)
	for _, m := range matches {
		if len(m) > 1 {
			url := m[1]
			if uniqueURLs[url] { continue }
			uniqueURLs[url] = true

			// Skip if already identified as a video URL
			if IsVideoURL(url) { continue }

			// Follow the redirect (using HEAD for efficiency)
			req, err := http.NewRequest("HEAD", url, nil)
			if err != nil { continue }
			req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")

			resp, err := client.Do(req)
			if err != nil { continue }
			resp.Body.Close()

			finalURL := resp.Request.URL.String()
			if IsVideoURL(finalURL) {
				sources = append(sources, models.Source{
					URL:     finalURL,
					Quality: DetectQuality(finalURL),
					Type:    detectType(finalURL),
				})
			}
		}
	}

	return sources
}
