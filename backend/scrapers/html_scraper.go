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
	Timeout: 15 * time.Second,
	CheckRedirect: func(req *http.Request, via []*http.Request) error {
		return nil // Follow redirects
	},
}

var (
	iframeRe         = regexp.MustCompile(`(?i)<iframe.*?src=["'](.*?)["']`)
	videoSourceRes   = []*regexp.Regexp{
		regexp.MustCompile(`https?://[^\s"']+\.m3u8[^\s"']*`),
		regexp.MustCompile(`https?://[^\s"']+\.mp4[^\s"']*`),
		regexp.MustCompile(`https?://[^\s"']+\.webm[^\s"']*`),
		regexp.MustCompile(`https?://[^\s"']+\.mkv[^\s"']*`),
		regexp.MustCompile(`https?://[^\s"']+\.mpd[^\s"']*`),
		regexp.MustCompile(`https?://[^\s"']+\.f4v[^\s"']*`),
		regexp.MustCompile(`https?://[^\s"']+\.flv[^\s"']*`),
		regexp.MustCompile(`file:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`source\s+(?:src|data-src|data-video|data-main)=["'](https?://.*?)["']`),
		regexp.MustCompile(`video_url\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`data-video-url=["'](https?://.*?)["']`),
		regexp.MustCompile(`["'](https?://[^\s"']+\.(?:m3u8|mp4|mpd|webm|mkv|avi|mov|flv|f4v))["']`),
		regexp.MustCompile(`(?:url|file|src)\s*[:=]\s*["'](https?://.*?)["']`),
	}
	jsVariableRes = []*regexp.Regexp{
		regexp.MustCompile(`["']?file["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`["']?sources["']?\s*:\s*\[(.*?)\]`),
		regexp.MustCompile(`["']?video_url["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`["']?url["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`["']?hls_url["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`["']?stream_url["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`["']?src["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`["']?link["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`["']?data["']?\s*:\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`var\s+\w+\s*=\s*["'](https?://.*?)["']`),
		regexp.MustCompile(`window\.config\s*=\s*(\{.*?\});`),
		regexp.MustCompile(`player\.setup\s*\((\{.*?\})\)`),
		regexp.MustCompile(`jwplayer\(.*?\)\.setup\((\{.*?\})\)`),
	}
	jsonConfigRe      = regexp.MustCompile(`(?s)\{.*?"(?:sources|playlist|file)".*?\}`)
	networkDiscoveryRes = []*regexp.Regexp{
		regexp.MustCompile(`["'](https?://[^"']*/api/v[0-9]/[^"']+)["']`),
		regexp.MustCompile(`["'](https?://[^"']*/ajax/[^"']+)["']`),
		regexp.MustCompile(`["'](https?://[^"']*/get_source/[^"']+)["']`),
		regexp.MustCompile(`["'](https?://[^"']*/playlist/[^"']+)["']`),
		regexp.MustCompile(`["'](https?://[^"']*/embed/sources/[^"']+)["']`),
		regexp.MustCompile(`["'](https?://[^"']*/getSources/[^"']+)["']`),
		regexp.MustCompile(`["'](https?://[^"']*/v[0-9]/sources/[^"']+)["']`),
		regexp.MustCompile(`["'](https?://[^"']*/player/get_playlist/[^"']+)["']`),
	}
)

func FetchHTML(url string) (string, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
	req.Header.Set("Referer", url)

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
	matches := iframeRe.FindAllStringSubmatch(html, -1)

	var urls []string
	for _, m := range matches {
		if len(m) > 1 {
			u := m[1]
			if strings.HasPrefix(u, "//") {
				u = "https:" + u
			}
			urls = append(urls, u)
		}
	}
	return urls
}

func ExtractVideoSources(html string) []string {
	// METHOD 1 – HTML PARSING & METHOD 5 - NETWORK DISCOVERY (MANIFESTS)
	var sources []string
	for _, re := range videoSourceRes {
		matches := re.FindAllStringSubmatch(html, -1)
		for _, m := range matches {
			if len(m) > 1 {
				sources = append(sources, m[1])
			} else if len(m) == 1 {
				sources = append(sources, m[0])
			}
		}
	}

	return sources
}

func ExtractJSVariables(html string) []string {
	// METHOD 3 – JAVASCRIPT VARIABLE PARSING
	var sources []string
	for _, re := range jsVariableRes {
		matches := re.FindAllStringSubmatch(html, -1)
		for _, m := range matches {
			if len(m) > 1 {
				content := m[1]
				if strings.HasPrefix(content, "{") {
					// Handle JSON captured by window.config or player.setup
					var data interface{}
					if err := json.Unmarshal([]byte(content), &data); err == nil {
						sources = append(sources, findURLsInJSON(data)...)
					}
				} else if strings.Contains(content, "http") {
					sources = append(sources, content)
				} else if strings.Contains(re.String(), `sources`) {
					// Recursive extraction for sources array
					innerRe := regexp.MustCompile(`["']?(?:file|src|url)["']?\s*:\s*["'](https?://.*?)["']`)
					innerMatches := innerRe.FindAllStringSubmatch(content, -1)
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
	// METHOD 4 – PLAYER CONFIG PARSING
	var sources []string
	// Look for JSON objects that might contain video sources (common in JWPlayer, Video.js)
	matches := jsonConfigRe.FindAllString(html, -1)

	for _, m := range matches {
		var data interface{}
		if err := json.Unmarshal([]byte(m), &data); err == nil {
			sources = append(sources, findURLsInJSON(data)...)
		}
	}
	return sources
}

func findURLsInJSON(data interface{}) []string {
	var urls []string
	switch v := data.(type) {
	case string:
		if strings.HasPrefix(v, "http") && (strings.Contains(v, ".mp4") || strings.Contains(v, ".m3u8") || strings.Contains(v, ".mpd") || strings.Contains(v, "/playlist/") || strings.Contains(v, "/manifest/")) {
			urls = append(urls, v)
		}
	case map[string]interface{}:
		for _, val := range v {
			urls = append(urls, findURLsInJSON(val)...)
		}
	case []interface{}:
		for _, val := range v {
			urls = append(urls, findURLsInJSON(val)...)
		}
	}
	return urls
}

func FollowRedirects(url string) (string, error) {
	// METHOD 6 – REDIRECT EXTRACTION
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
	req.Header.Set("Range", "bytes=0-0")

	resp, err := client.Do(req)
	if err != nil {
		return url, err
	}
	defer resp.Body.Close()
	return resp.Request.URL.String(), nil
}

func ExtractEmbeds(html string) []string {
	// METHOD 7 – EMBED PROVIDER EXTRACTION
	embedProviders := []string{
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

func ExtractNetworkDiscovery(html string) []string {
	// METHOD 5 - NETWORK REQUEST DISCOVERY
	// Looking for API endpoints or AJAX calls that might return video links
	var endpoints []string
	for _, re := range networkDiscoveryRes {
		matches := re.FindAllStringSubmatch(html, -1)
		for _, m := range matches {
			if len(m) > 1 {
				endpoints = append(endpoints, m[1])
			}
		}
	}
	return endpoints
}
