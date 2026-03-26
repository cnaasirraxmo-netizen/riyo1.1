package services

import (
	"context"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/riyobox/backend/scrapers"
)

type ScrapedSource struct {
	URL      string `json:"url"`
	Type     string `json:"type"`
	Quality  string `json:"quality"`
	Provider string `json:"provider"`
}

type ScraperService struct {
	finder *scrapers.UniversalFinder
	client *http.Client
}

func NewScraperService() *ScraperService {
	return &ScraperService{
		finder: scrapers.NewUniversalFinder(),
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (s *ScraperService) Scrape(url string) ([]ScrapedSource, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	return s.ScrapeWithContext(ctx, url)
}

func (s *ScraperService) ScrapeWithContext(ctx context.Context, url string) ([]ScrapedSource, error) {
	// Using the existing finder which already implements multiple strategies (iframes, JS, JSON, etc.)
	links := s.finder.FindSourcesWithContext(ctx, url)

	var sources []ScrapedSource
	var mu sync.Mutex

	// Prepare tasks for the worker pool
	tasks := make([]scrapers.WorkerTask, len(links))
	for i, link := range links {
		tasks[i] = scrapers.WorkerTask{
			URL: link,
			ScrapeFn: func(l string) ([]string, error) {
				// We don't really need to scrape further here, just validate
				if isValid, ct := s.ValidateLink(l); isValid {
					mu.Lock()
					sources = append(sources, ScrapedSource{
						URL:     l,
						Type:    s.DetectType(l, ct),
						Quality: s.finder.DetectQuality(l),
					})
					mu.Unlock()
				}
				return nil, nil
			},
		}
	}

	// Concurrent validation with worker pool (max 3 concurrent as requested)
	scrapers.RunWorkerPool(ctx, tasks, 3)

	return sources, nil
}

func (s *ScraperService) ValidateLink(url string) (bool, string) {
	return scrapers.ValidateURL(url)
}

func (s *ScraperService) DetectType(url, ct string) string {
	if strings.Contains(url, ".m3u8") || strings.Contains(ct, "mpegurl") {
		return "hls"
	}
	if strings.Contains(url, ".mpd") || strings.Contains(ct, "dash+xml") {
		return "dash"
	}
	return "mp4" // default
}
