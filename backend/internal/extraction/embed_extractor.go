package extraction

import (
	"io"
	"net/http"
	"strings"
	"time"
	"github.com/riyobox/backend/internal/models"
)

var (
	// List of known embed provider patterns
	embedProviders = []string{
		"vidsrc.to",
		"2embed.cc",
		"multiembed.mov",
		"vidlink.pro",
		"player.autoembed.cc",
		"vidsrc.me",
		"superembed.stream",
		"embed.su",
		"vidsrc.xyz",
		"vidsrc.cc",
	}
)

// ExtractEmbeds identifies embed URLs from the HTML, fetches their content, and runs ExtractAll on them.
func ExtractEmbeds(html string) []models.Source {
	var sources []models.Source

	// Discover iframes that match embed provider patterns
	iframes := ExtractIframes(html) // Reuse iframe discovery logic

	uniqueEmbeds := make(map[string]bool)
	for _, iframeURL := range iframes {
		for _, provider := range embedProviders {
			if strings.Contains(iframeURL, provider) {
				if uniqueEmbeds[iframeURL] { continue }
				uniqueEmbeds[iframeURL] = true

				// Fetch the embed page and recurse
				embedHTML, err := fetchHTML(iframeURL)
				if err == nil {
					// Recurse into the embed HTML using ExtractAll (via a circular dependency management)
					sources = append(sources, ExtractAll(embedHTML)...)
				}
				break
			}
		}
	}

	return sources
}

func fetchHTML(url string) (string, error) {
	client := &http.Client{Timeout: 15 * time.Second}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")
	req.Header.Set("Referer", url)

	resp, err := client.Do(req)
	if err != nil { return "", err }
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil { return "", err }
	return string(body), nil
}
