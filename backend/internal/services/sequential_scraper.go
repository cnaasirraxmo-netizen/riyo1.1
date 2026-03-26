package services

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"
)

type SequentialScraper struct {
	registry *ProviderRegistry
	scraper  *ScraperService
}

func NewSequentialScraper(registry *ProviderRegistry, scraper *ScraperService) *SequentialScraper {
	return &SequentialScraper{
		registry: registry,
		scraper:  scraper,
	}
}

func (s *SequentialScraper) GetFirstWorkingSource(ctx context.Context, tmdbID string, season, episode int) (*ScrapedSource, []string, error) {
	contentType := "movie"
	if season > 0 || episode > 0 {
		contentType = "tv"
	}

	providers := s.registry.GetProviders(contentType)
	var failedProviders []string

	for _, p := range providers {
		select {
		case <-ctx.Done():
			return nil, failedProviders, ctx.Err()
		default:
			// 1. Generate URL
			embedURL, err := GenerateURL(p, tmdbID, season, episode)
			if err != nil {
				log.Printf("[SEQUENTIAL] Error generating URL for %s: %v", p.Name, err)
				failedProviders = append(failedProviders, p.Name+" (Invalid URL)")
				continue
			}

			// 2. Scrape with provider-specific timeout
			timeout := time.Duration(p.TimeoutSeconds) * time.Second
			if timeout == 0 {
				timeout = 15 * time.Second
			}

			pCtx, pCancel := context.WithTimeout(ctx, timeout)

			log.Printf("[SEQUENTIAL] Trying provider: %s | URL: %s", p.Name, embedURL)

			// Use ScrapeWithContext for correct integration
			sources, err := s.scraper.ScrapeWithContext(pCtx, embedURL)
			pCancel()

			if err != nil {
				log.Printf("[SEQUENTIAL] Provider %s failed: %v", p.Name, err)
				failedProviders = append(failedProviders, p.Name+" ("+err.Error()+")")
				continue
			}

			if len(sources) > 0 {
				// Success! Take the best source from this provider
				best := s.pickBestFromProvider(sources)
				best.Provider = p.Name
				log.Printf("[SEQUENTIAL] SUCCESS with provider %s! Stopping.", p.Name)
				return &best, failedProviders, nil
			}

			log.Printf("[SEQUENTIAL] Provider %s returned no valid sources", p.Name)
			failedProviders = append(failedProviders, p.Name+" (No video)")
		}
	}

	return nil, failedProviders, fmt.Errorf("all providers failed: %s", strings.Join(failedProviders, ", "))
}

func (s *SequentialScraper) pickBestFromProvider(sources []ScrapedSource) ScrapedSource {
	// Simple ranking: HLS > MP4, 1080p > 720p
	qualityMap := map[string]int{
		"4K":    5,
		"1080p": 4,
		"720p":  3,
		"480p":  2,
		"360p":  1,
	}
	typeMap := map[string]int{
		"hls":  3,
		"dash": 2,
		"mp4":  1,
	}

	best := sources[0]
	bestScore := qualityMap[best.Quality]*10 + typeMap[best.Type]

	for i := 1; i < len(sources); i++ {
		score := qualityMap[sources[i].Quality]*10 + typeMap[sources[i].Type]
		if score > bestScore {
			bestScore = score
			best = sources[i]
		}
	}
	return best
}
