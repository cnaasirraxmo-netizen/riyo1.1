package utils

import (
	"fmt"
)

type Subtitle struct {
	Language string `json:"language"`
	URL      string `json:"url"`
}

func GetSubtitles(tmdbID int, isTvShow bool, season, episode int) []Subtitle {
	// In a real implementation, you would use OpenSubtitles API or similar
	// Example: https://api.opensubtitles.com/api/v1/subtitles?tmdb_id={tmdb_id}

	subtitles := []Subtitle{
		{Language: "English", URL: fmt.Sprintf("https://example.com/subs/%d_en.vtt", tmdbID)},
		{Language: "Arabic", URL: fmt.Sprintf("https://example.com/subs/%d_ar.vtt", tmdbID)},
	}

	return subtitles
}
