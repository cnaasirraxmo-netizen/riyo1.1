package scrapers

import (
	"io"
	"net/http"
	"regexp"
)

func FetchHTML(url string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(body), nil
}

func ExtractIframes(html string) []string {
	re := regexp.MustCompile(`(?i)<iframe.*?src=["'](.*?)["']`)
	matches := re.FindAllStringSubmatch(html, -1)

	var urls []string
	for _, m := range matches {
		if len(m) > 1 {
			urls = append(urls, m[1])
		}
	}
	return urls
}

func ExtractVideoSources(html string) []string {
	// Patterns for common video formats and source variables
	patterns := []string{
		`https?://[^\s"']+\.m3u8[^\s"']*`,
		`https?://[^\s"']+\.mp4[^\s"']*`,
		`file:\s*["'](https?://.*?)["']`,
		`source\s+src=["'](https?://.*?)["']`,
	}

	var sources []string
	for _, p := range patterns {
		re := regexp.MustCompile(p)
		matches := re.FindAllString(html, -1)
		sources = append(sources, matches...)
	}

	return sources
}
