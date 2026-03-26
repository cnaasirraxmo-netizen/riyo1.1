package services

import (
	"context"
	"log"
	"strings"
	"time"

	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
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

		// Add the primary Embed Source (as requested, always show these providers)
		allSources = append(allSources, models.StreamSource{
			Label:    p.Name,
			URL:      url,
			Type:     "embed",
			Provider: strings.ToLower(p.Name),
			Quality:  "720p",
		})
	}

	// STEP 4 & 5: REQUEST EMBED PAGE & UNIVERSAL VIDEO FINDER
	// Concurrently extract direct streaming links from the embed providers
	scraped := s.extractor.ExtractSources(tmdbID, title, false, 0, 0)
	allSources = append(allSources, scraped...)

	// STEP 6: MERGE SOURCES & REMOVE DUPLICATES
	deduped := s.extractor.deduplicateSources(allSources)

	// STEP 9: SOURCE RANKING (Ensure high quality direct links are prioritized)
	ranked := s.extractor.rankSources(deduped)

	// STEP 11: STORE IN DATABASE (Persistence)
	go s.PersistMovieSources(tmdbID, ranked)

	return ranked
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

	// STEP 6 & 9
	deduped := s.extractor.deduplicateSources(allSources)
	ranked := s.extractor.rankSources(deduped)

	// STEP 11: STORE IN DATABASE (Persistence)
	go s.PersistTVShowSources(tmdbID, season, episode, ranked)

	return ranked
}

// PersistMovieSources implements STEP 11: STORE IN DATABASE.
func (s *ScraperService) PersistMovieSources(tmdbID int, sources []models.StreamSource) {
	collection := db.DB.Collection("movies")
	update := bson.M{
		"$set": bson.M{
			"sources":   sources,
			"isScraped": true,
			"updatedAt": time.Now(),
		},
	}
	_, err := collection.UpdateOne(context.TODO(), bson.M{"tmdbId": tmdbID}, update)
	if err != nil {
		log.Printf("[PERSISTENCE] Failed to store movie sources for %d: %v", tmdbID, err)
	} else {
		log.Printf("[PERSISTENCE] Successfully stored %d sources for movie %d", len(sources), tmdbID)
	}
}

// PersistTVShowSources implements STEP 11: STORE IN DATABASE for TV episodes.
func (s *ScraperService) PersistTVShowSources(tmdbID int, season, episode int, sources []models.StreamSource) {
	collection := db.DB.Collection("movies")

	filter := bson.M{
		"tmdbId": tmdbID,
	}

	update := bson.M{
		"$set": bson.M{
			"seasons.$[s].episodes.$[e].sources": sources,
			"updatedAt":                           time.Now(),
		},
	}

	arrayFilters := []interface{}{
		bson.M{"s.number": season},
		bson.M{"e.number": episode},
	}

	opts := options.UpdateOne().SetArrayFilters(arrayFilters)

	_, err := collection.UpdateOne(context.TODO(), filter, update, opts)
	if err != nil {
		log.Printf("[PERSISTENCE] Failed to store TV sources for %d S%dE%d: %v", tmdbID, season, episode, err)
	} else {
		log.Printf("[PERSISTENCE] Successfully stored %d sources for TV %d S%dE%d", len(sources), tmdbID, season, episode)
	}
}
