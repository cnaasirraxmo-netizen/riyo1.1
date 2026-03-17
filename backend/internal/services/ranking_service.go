package services

import (
	"strings"
	"github.com/riyobox/backend/internal/models"
)

// RankSources sorts the final sources by quality and provider priority.
func RankSources(sources []models.Source) []models.Source {
	qualityMap := map[string]int{
		"4K":    50,
		"1080p": 40,
		"720p":  30,
		"480p":  20,
		"360p":  10,
	}

	// Provider reliability scores (higher = more reliable)
	providerReliability := map[string]int{
		"vidsrc":      10,
		"vidlink":     9,
		"superembed":  8,
		"2embed":      7,
		"vidsrcpro":   10,
	}

	for i := 0; i < len(sources); i++ {
		for j := i + 1; j < len(sources); j++ {
			pI := providerReliability[strings.ToLower(sources[i].Provider)]
			pJ := providerReliability[strings.ToLower(sources[j].Provider)]

			scoreI := qualityMap[sources[i].Quality] + pI
			scoreJ := qualityMap[sources[j].Quality] + pJ

			if scoreJ > scoreI {
				sources[i], sources[j] = sources[j], sources[i]
			}
		}
	}

	return sources
}
