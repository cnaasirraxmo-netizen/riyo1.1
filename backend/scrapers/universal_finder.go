package scrapers

import (
	"context"
	"log"
	"net/url"
	"strings"
	"sync"
	"time"
)

type UniversalFinder struct {
	headlessRod *HeadlessScraperRod
	semaphore   chan struct{}
}

func NewUniversalFinder() *UniversalFinder {
	return &UniversalFinder{
		headlessRod: NewHeadlessScraperRod(),
		semaphore:   make(chan struct{}, 10), // Limit concurrent recursive scrapes
	}
}

func (f *UniversalFinder) FindSources(targetURL string) []string {
	// Root context for the search - REDUCED: 75s -> 25s
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	var allResults []string

	// 1. FAST PATH ONLY: Static HTML/Regex (Disable dynamic path to save RAM/CPU)
	visited := &sync.Map{}
	fastSources := f.recursiveFind(ctx, targetURL, 0, visited)
	allResults = append(allResults, fastSources...)

	// 2. DYNAMIC PATH: Headless Browser (Only run if no sources found AND highly needed)
	if len(allResults) == 0 {
		// Run Rod in same thread or restricted to prevent RAM spikes
		dynamicSources := f.headlessRod.ExtractSources(ctx, targetURL)
		allResults = append(allResults, dynamicSources...)
	}

	return f.uniqueSources(allResults)
}

func (f *UniversalFinder) recursiveFind(ctx context.Context, targetURL string, depth int, visited *sync.Map) []string {
	// REDUCED DEPTH: 4 -> 2 to prevent excessive resource usage
	if depth > 2 {
		return nil
	}

	// Check visited in thread-safe way
	if _, seen := visited.LoadOrStore(targetURL, true); seen {
		return nil
	}

	// Rate limiting/Concurrency control
	select {
	case f.semaphore <- struct{}{}:
		defer func() { <-f.semaphore }()
	case <-ctx.Done():
		return nil
	}

	var allSources []string
	var mu sync.Mutex

	// 1. REDIRECT EXTRACTION (METHOD 6)
	finalURL, _ := FollowRedirects(targetURL)
	html, err := FetchHTML(finalURL)
	if err != nil {
		return nil
	}

	// 2. EMBED PROVIDER EXTRACTION (METHOD 7)
	embeds := ExtractEmbeds(html)
	mu.Lock()
	allSources = append(allSources, embeds...)
	mu.Unlock()

	// 3. IFRAME EXTRACTION (METHOD 2) - Recursive discovery
	iframes := ExtractIframes(html)
	var wg sync.WaitGroup
	for _, iframe := range iframes {
		wg.Add(1)
		go func(iframeURL string) {
			defer wg.Done()
			discovered := f.recursiveFind(ctx, iframeURL, depth+1, visited)
			mu.Lock()
			allSources = append(allSources, discovered...)
			mu.Unlock()
		}(iframe)
	}

	// 4. HTML PARSING (METHOD 1)
	htmlSources := ExtractVideoSources(html)
	mu.Lock()
	allSources = append(allSources, htmlSources...)
	mu.Unlock()

	// 5. JAVASCRIPT VARIABLE PARSING (METHOD 3)
	jsSources := ExtractJSVariables(html)
	mu.Lock()
	allSources = append(allSources, jsSources...)
	mu.Unlock()

	// 6. PLAYER CONFIG PARSING (METHOD 4)
	jsonSources := ExtractJSONConfig(html)
	mu.Lock()
	allSources = append(allSources, jsonSources...)
	mu.Unlock()

	// 7. NETWORK REQUEST DISCOVERY (METHOD 5)
	networkEndpoints := ExtractNetworkDiscovery(html)
	for _, endpoint := range networkEndpoints {
		wg.Add(1)
		go func(ep string) {
			defer wg.Done()
			// Fetch the endpoint and extract potential video links from it
			respHTML, err := FetchHTML(ep)
			if err == nil {
				s := ExtractVideoSources(respHTML)
				js := ExtractJSVariables(respHTML)
				json := ExtractJSONConfig(respHTML)
				mu.Lock()
				allSources = append(allSources, s...)
				allSources = append(allSources, js...)
				allSources = append(allSources, json...)
				mu.Unlock()
			}
		}(endpoint)
	}

	wg.Wait()

	// Final Step: Follow redirects for all found sources
	var finalSources []string
	for _, s := range allSources {
		fSource, _ := FollowRedirects(s)
		finalSources = append(finalSources, fSource)
	}

	return f.uniqueSources(finalSources)
}

func (f *UniversalFinder) uniqueSources(sources []string) []string {
	keys := make(map[string]bool)
	var list []string
	for _, entry := range sources {
		normalized := f.normalizeURL(entry)
		if normalized == "" {
			continue
		}
		if _, value := keys[normalized]; !value {
			keys[normalized] = true
			list = append(list, entry)
			log.Printf("[FINDER] Valid Source Found: %s", entry)
		}
	}
	return list
}

func (f *UniversalFinder) normalizeURL(rawURL string) string {
	u, err := url.Parse(rawURL)
	if err != nil {
		return strings.ToLower(rawURL)
	}

	// Remove common tracking and cache-busting parameters
	q := u.Query()
	paramsToRemove := []string{"token", "expires", "ip", "v", "key", "t", "st", "e", "verify"}
	for _, p := range paramsToRemove {
		q.Del(p)
	}

	u.RawQuery = q.Encode()
	u.Fragment = "" // Fragments are usually not part of the direct video URL

	return strings.ToLower(u.String())
}

func (f *UniversalFinder) IsValidVideo(url string) bool {
	// Simple pre-filter check
	lower := strings.ToLower(url)
	validExts := []string{".m3u8", ".mp4", ".mpd", ".webm", ".mkv", ".f4v", ".flv", "/manifest/", "/playlist/"}
	for _, ext := range validExts {
		if strings.Contains(lower, ext) {
			return true
		}
	}
	return false
}

func (f *UniversalFinder) DetectQuality(url string) string {
	lowerURL := strings.ToLower(url)
	if strings.Contains(lowerURL, "2160") || strings.Contains(lowerURL, "4k") || strings.Contains(lowerURL, "uhd") {
		return "4K"
	}
	if strings.Contains(lowerURL, "1080") || strings.Contains(lowerURL, "fhd") || strings.Contains(lowerURL, "fullhd") || strings.Contains(lowerURL, "1920x1080") {
		return "1080p"
	}
	if strings.Contains(lowerURL, "720") || strings.Contains(lowerURL, "hd") || strings.Contains(lowerURL, "1280x720") {
		return "720p"
	}
	if strings.Contains(lowerURL, "480") || strings.Contains(lowerURL, "sd") || strings.Contains(lowerURL, "854x480") {
		return "480p"
	}
	if strings.Contains(lowerURL, "360") || strings.Contains(lowerURL, "640x360") {
		return "360p"
	}
	return "720p"
}
