package extraction

import (
	"encoding/json"
	"regexp"
	"github.com/riyobox/backend/internal/models"
)

var (
	// Look for JSON objects that might contain video sources
	jsonConfigRe = regexp.MustCompile(`(?s)\{.*?"(?:sources|playlist|file)".*?\}`)
)

// ExtractJSON detects and parses JSON objects containing player configurations.
func ExtractJSON(html string) []models.Source {
	var sources []models.Source
	matches := jsonConfigRe.FindAllString(html, -1)

	for _, m := range matches {
		var data interface{}
		// Basic JSON validation and safe parsing
		if err := json.Unmarshal([]byte(m), &data); err == nil {
			sources = append(sources, findURLsInJSON(data)...)
		}
	}

	return sources
}
