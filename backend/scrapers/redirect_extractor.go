package scrapers

import (
	"net/http"
	"regexp"
	"time"
)

var (
	// Regex for finding potential redirect URLs in the HTML (links that aren't already videos)
	redirectRe = regexp.MustCompile(`(?i)href=["'](https?://[^"']*(?:redirect|go|out|visit|link|short|url|to|play|player|embed|v|f|s|download|get|stream|api|ajax)[^"']*)["']`)
)

// ExtractRedirects follows potential redirect links found in the HTML to find direct video URLs.
func ExtractRedirects(html string) []string {
	var sources []string
	matches := redirectRe.FindAllStringSubmatch(html, -1)

	client := &http.Client{
		Timeout: 10 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return http.ErrUseLastResponse
			}
			return nil
		},
	}

	uniqueRedirects := make(map[string]bool)
	for _, m := range matches {
		if len(m) > 1 {
			url := m[1]
			// Avoid re-processing the same redirect link
			if uniqueRedirects[url] {
				continue
			}
			uniqueRedirects[url] = true

			// Already a video link? Skip it, as it'll be caught by ExtractVideoSources.
			if isVideoURL(url) {
				continue
			}

			// Follow the redirect
			req, err := http.NewRequest("HEAD", url, nil)
			if err != nil {
				continue
			}
			req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")

			resp, err := client.Do(req)
			if err != nil {
				continue
			}
			resp.Body.Close()

			finalURL := resp.Request.URL.String()
			if isVideoURL(finalURL) {
				sources = append(sources, finalURL)
			}
		}
	}

	return sources
}
