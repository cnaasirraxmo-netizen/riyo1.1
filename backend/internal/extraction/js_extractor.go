package extraction

import (
	"encoding/json"
	"regexp"
	"github.com/riyobox/backend/internal/models"
)

var (
	// Patterns for JS variables and arrays
	jsVarRe      = regexp.MustCompile(`(?i)["']?(?:file|src|url|hls_url|stream_url)["']?\s*:\s*["'](https?://[^"']*(?:\.m3u8|\.mp4|\.mpd|\.webm|\.mkv)[^"']*)["']`)
	jsSourcesRe  = regexp.MustCompile(`(?i)["']?sources["']?\s*:\s*\[(.*?)\]`)
	jsConfigRe   = regexp.MustCompile(`(?i)(?:window\.config|player\.setup|jwplayer\(.*?\)\.setup)\s*\((\{.*?\})\)`)
)

// ExtractJS extracts video sources from <script> tags and JS variables.
func ExtractJS(html string) []models.Source {
	var sources []models.Source

	// 1. Direct variable/key match
	matches := jsVarRe.FindAllStringSubmatch(html, -1)
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

	// 2. Sources array match (nested links)
	sMatches := jsSourcesRe.FindAllStringSubmatch(html, -1)
	for _, m := range sMatches {
		if len(m) > 1 {
			innerRe := regexp.MustCompile(`["']?(?:file|src|url)["']?\s*:\s*["'](https?://[^"']*(?:\.mp4|\.m3u8|\.mpd)[^"']*)["']`)
			innerMatches := innerRe.FindAllStringSubmatch(m[1], -1)
			for _, im := range innerMatches {
				if len(im) > 1 {
					url := im[1]
					sources = append(sources, models.Source{
						URL:     url,
						Quality: DetectQuality(url),
						Type:    detectType(url),
					})
				}
			}
		}
	}

	// 3. Player config JSON match
	cMatches := jsConfigRe.FindAllStringSubmatch(html, -1)
	for _, m := range cMatches {
		if len(m) > 1 {
			// Try to clean up common JS object syntax that isn't strict JSON
			cleanedJSON := cleanJSObject(m[1])
			var data interface{}
			if err := json.Unmarshal([]byte(cleanedJSON), &data); err == nil {
				sources = append(sources, findURLsInJSON(data)...)
			}
		}
	}

	return sources
}

// cleanJSObject attempts to convert a JS object string to valid JSON.
func cleanJSObject(js string) string {
	// 1. Ensure keys are quoted
	reKeys := regexp.MustCompile(`([{,])\s*([a-zA-Z0-9_]+)\s*:`)
	cleaned := reKeys.ReplaceAllString(js, `$1"$2":`)
	// 2. Convert single quotes to double quotes for values
	reValues := regexp.MustCompile(`:\s*'([^']*)'`)
	cleaned = reValues.ReplaceAllString(cleaned, `:"$1"`)
	return cleaned
}

func findURLsInJSON(data interface{}) []models.Source {
	var sources []models.Source
	switch v := data.(type) {
	case string:
		if IsVideoURL(v) {
			sources = append(sources, models.Source{
				URL:     v,
				Quality: DetectQuality(v),
				Type:    detectType(v),
			})
		}
	case map[string]interface{}:
		for _, val := range v {
			sources = append(sources, findURLsInJSON(val)...)
		}
	case []interface{}:
		for _, val := range v {
			sources = append(sources, findURLsInJSON(val)...)
		}
	}
	return sources
}
