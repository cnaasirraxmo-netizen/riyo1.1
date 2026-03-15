package scrapers

import (
	"encoding/json"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"
)

var client = &http.Client{
	Timeout: 10 * time.Second,
	CheckRedirect: func(req *http.Request, via []*http.Request) error {
		return nil // Follow redirects
	},
}

func FetchHTML(url string) (string, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

	resp, err := client.Do(req)
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

func ExtractJSVariables(html string) []string {
	patterns := []string{
		`["']?file["']?\s*:\s*["'](https?://.*?)["']`,
		`["']?sources["']?\s*:\s*\[(.*?)\]`,
		`["']?video_url["']?\s*:\s*["'](https?://.*?)["']`,
	}

	var sources []string
	for _, p := range patterns {
		re := regexp.MustCompile(p)
		matches := re.FindAllStringSubmatch(html, -1)
		for _, m := range matches {
			if len(m) > 1 {
				if strings.Contains(m[1], "http") {
					sources = append(sources, m[1])
				} else if p == `["']?sources["']?\s*:\s*\[(.*?)\]` {
					// Handle cases like sources: [{file: "..."}]
					innerRe := regexp.MustCompile(`["']?file["']?\s*:\s*["'](https?://.*?)["']`)
					innerMatches := innerRe.FindAllStringSubmatch(m[1], -1)
					for _, im := range innerMatches {
						if len(im) > 1 {
							sources = append(sources, im[1])
						}
					}
				}
			}
		}
	}
	return sources
}

func ExtractJSONConfig(html string) []string {
	var sources []string
	// Look for JSON objects that might contain video sources
	re := regexp.MustCompile(`(?s)\{.*?"sources".*?\]\s*\}`)
	matches := re.FindAllString(html, -1)

	for _, m := range matches {
		var data map[string]interface{}
		if err := json.Unmarshal([]byte(m), &data); err == nil {
			if s, ok := data["sources"].([]interface{}); ok {
				for _, source := range s {
					if srcMap, ok := source.(map[string]interface{}); ok {
						if file, ok := srcMap["file"].(string); ok {
							sources = append(sources, file)
						}
						if src, ok := srcMap["src"].(string); ok {
							sources = append(sources, src)
						}
					}
				}
			}
		}
	}
	return sources
}

func FollowRedirects(url string) (string, error) {
	resp, err := client.Head(url)
	if err != nil {
		return url, err
	}
	defer resp.Body.Close()
	return resp.Request.URL.String(), nil
}

func ExtractEmbeds(html string) []string {
	embedProviders := []string{
		"vidsrc.to",
		"2embed.cc",
		"multiembed.mov",
		"vidlink.pro",
		"player.autoembed.cc",
		"vidsrc.me",
	}

	var embeds []string
	iframes := ExtractIframes(html)
	for _, iframe := range iframes {
		for _, provider := range embedProviders {
			if strings.Contains(iframe, provider) {
				embeds = append(embeds, iframe)
				break
			}
		}
	}
	return embeds
}
