package services

import (
	"log"
	"strings"

	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
)

// ScraperService implements Steps 3 and 4 of the Scraping Pipeline.
type ScraperService struct {
	extractor *VideoExtractor
}

func NewScraperService(ext *VideoExtractor) *ScraperService {
	return &ScraperService{extractor: ext}
}

// GetMovieSources implements STEP 3 & 4: PROVIDER GENERATE EMBED LINKS and REQUEST EMBED PAGE.
func (s *ScraperService) GetMovieSources(tmdbID int, title string) []models.StreamSource {
	log.Printf("[SCRAPER] Starting worker job for Movie TMDb ID: %d", tmdbID)

	// STEP 3: PROVIDERS GENERATE EMBED LINKS
	embedProviders := providers.GetEmbedProviders()
	var allSources []models.StreamSource

	for _, p := range embedProviders {
		url := providers.GenerateMovieURL(p, tmdbID)

		// Add the Embed link itself
		allSources = append(allSources, models.StreamSource{
			Label:    p.Name,
			URL:      url,
			Type:     "embed",
			Provider: strings.ToLower(p.Name),
			Quality:  "720p",
		})
	}

	// STEP 4 & 5: REQUEST EMBED PAGE & UNIVERSAL VIDEO FINDER
	// This is handled concurrently inside VideoExtractor.ExtractSources
	scraped := s.extractor.ExtractSources(tmdbID, title, false, 0, 0)
	allSources = append(allSources, scraped...)

	return s.extractor.deduplicateSources(allSources)
}

// GetTVShowSources implements STEP 3 & 4 for TV shows.
func (s *ScraperService) GetTVShowSources(tmdbID int, title string, season, episode int) []models.StreamSource {
	log.Printf("[SCRAPER] Starting worker job for TV Show TMDb ID: %d (S%dE%d)", tmdbID, season, episode)

	// STEP 3: PROVIDERS GENERATE EMBED LINKS
	embedProviders := providers.GetTVEmbedProviders()
	var allSources []models.StreamSource

	for _, p := range embedProviders {
		url := providers.GenerateTVURL(p, tmdbID, season, episode)

		allSources = append(allSources, models.StreamSource{
			Label:    p.Name,
			URL:      url,
			Type:     "embed",
			Provider: strings.ToLower(p.Name),
			Quality:  "720p",
		})
	}

	// STEP 4 & 5: REQUEST EMBED PAGE & UNIVERSAL VIDEO FINDER
	scraped := s.extractor.ExtractSources(tmdbID, title, true, season, episode)
	allSources = append(allSources, scraped...)

	return s.extractor.deduplicateSources(allSources)
}
