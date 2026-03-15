package services

import (
	"strings"
	"sync"

	"github.com/riyobox/backend/scrapers"
)

type UniversalFinder struct{}

func NewUniversalFinder() *UniversalFinder {
	return &UniversalFinder{}
}

func (f *UniversalFinder) FindSources(url string) []string {
	var allSources []string
	var mu sync.Mutex

	html, err := scrapers.FetchHTML(url)
	if err != nil {
		return nil
	}

	// 1. Try HTML parsing
	htmlSources := scrapers.ExtractVideoSources(html)
	mu.Lock()
	allSources = append(allSources, htmlSources...)
	mu.Unlock()

	// 2. Try iframe extraction
	iframes := scrapers.ExtractIframes(html)
	var wg sync.WaitGroup
	for _, iframe := range iframes {
		wg.Add(1)
		go func(iframeURL string) {
			defer wg.Done()
			// Recursively try to find sources in iframes (depth 1)
			iframeHTML, err := scrapers.FetchHTML(iframeURL)
			if err == nil {
				s := scrapers.ExtractVideoSources(iframeHTML)
				js := scrapers.ExtractJSVariables(iframeHTML)
				mu.Lock()
				allSources = append(allSources, s...)
				allSources = append(allSources, js...)
				mu.Unlock()
			}
		}(iframe)
	}

	// 3. Try JavaScript parsing
	jsSources := scrapers.ExtractJSVariables(html)
	mu.Lock()
	allSources = append(allSources, jsSources...)
	mu.Unlock()

	// 4. Try JSON config parsing
	jsonSources := scrapers.ExtractJSONConfig(html)
	mu.Lock()
	allSources = append(allSources, jsonSources...)
	mu.Unlock()

	// 5. Try embed extraction
	embeds := scrapers.ExtractEmbeds(html)
	mu.Lock()
	allSources = append(allSources, embeds...)
	mu.Unlock()

	// 6. Try redirect detection (handled by FetchHTML/FollowRedirects if needed)

	wg.Wait()

	return f.uniqueSources(allSources)
}

func (f *UniversalFinder) uniqueSources(sources []string) []string {
	keys := make(map[string]bool)
	var list []string
	for _, entry := range sources {
		if _, value := keys[entry]; !value && entry != "" {
			keys[entry] = true
			list = append(list, entry)
		}
	}
	return list
}

func (f *UniversalFinder) DetectQuality(url string) string {
	if strings.Contains(url, "1080") {
		return "1080p"
	}
	if strings.Contains(url, "720") {
		return "720p"
	}
	if strings.Contains(url, "480") {
		return "480p"
	}
	return "720p" // Default
}
