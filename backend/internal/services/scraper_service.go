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
	// 15 second timeout per URL as requested
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// Using the existing finder which already implements multiple strategies (iframes, JS, JSON, etc.)
	links := s.finder.FindSources(url)

	var sources []ScrapedSource
	var wg sync.WaitGroup
	var mu sync.Mutex

	// Concurrent validation with worker pool (max 3 concurrent)
	sem := make(chan struct{}, 3)

	for _, link := range links {
		wg.Add(1)
		go func(l string) {
			defer wg.Done()
			select {
			case sem <- struct{}{}:
				defer func() { <-sem }()
			case <-ctx.Done():
				return
			}

			if isValid, ct := s.ValidateLink(l); isValid {
				mu.Lock()
				sources = append(sources, ScrapedSource{
					URL:     l,
					Type:    s.DetectType(l, ct),
					Quality: s.finder.DetectQuality(l),
				})
				mu.Unlock()
			}
		}(link)
	}

	wg.Wait()
	return sources, nil
}

func (s *ScraperService) ValidateLink(url string) (bool, string) {
	req, err := http.NewRequest("HEAD", url, nil)
	if err != nil {
		return false, ""
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

	resp, err := s.client.Do(req)
	if err != nil {
		// Fallback to GET for some providers that don't support HEAD
		req.Method = "GET"
		req.Header.Set("Range", "bytes=0-0")
		resp, err = s.client.Do(req)
		if err != nil {
			return false, ""
		}
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusPartialContent {
		ct := strings.ToLower(resp.Header.Get("Content-Type"))
		isValid := strings.Contains(ct, "video/") ||
			strings.Contains(ct, "mpegurl") ||
			strings.Contains(ct, "dash+xml") ||
			strings.Contains(ct, "application/octet-stream")
		return isValid, ct
	}

	return false, ""
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
