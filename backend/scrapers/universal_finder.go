package scrapers

import (
	"context"
	"log"
	"net/url"
	"strings"
	"sync"
	"time"
)

// UniversalFinder implements the "STEP 5 — UNIVERSAL VIDEO FINDER" pipeline.
// It searches for streaming links using 7-8 distinct extraction methods.
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
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	return f.FindSourcesWithContext(ctx, targetURL)
}

func (f *UniversalFinder) FindSourcesWithContext(ctx context.Context, targetURL string) []string {
	var allResults []string
	log.Printf("[FINDER] Starting search for URL: %s", targetURL)

	// 1. FAST PATH: Static HTML/Regex discovery
	visited := &sync.Map{}
	fastSources := f.recursiveFind(ctx, targetURL, 0, visited)
	allResults = append(allResults, fastSources...)

	// 2. DYNAMIC PATH: Headless Browser (METHOD 5 & General Discovery)
	// If the fast path yields few results or the URL is known for JS dependency,
	// we use a headless browser to "sniff" traffic and parse dynamic DOM.
	if len(allResults) < 2 {
		log.Printf("[FINDER] Few/No sources found statically, attempting Dynamic Path for: %s", targetURL)
		dynamicSources := f.headlessRod.ExtractSources(ctx, targetURL)
		allResults = append(allResults, dynamicSources...)
	}

	return f.UniqueSources(allResults)
}

func (f *UniversalFinder) recursiveFind(ctx context.Context, targetURL string, depth int, visited *sync.Map) []string {
	// Recursive depth limit to prevent infinite loops and resource exhaustion
	if depth > 2 {
		return nil
	}

	// Avoid re-visiting the same URL in the same extraction tree
	if _, seen := visited.LoadOrStore(targetURL, true); seen {
		return nil
	}

	// Concurrency control to avoid overwhelming system or target
	select {
	case f.semaphore <- struct{}{}:
		defer func() { <-f.semaphore }()
	case <-ctx.Done():
		return nil
	}

	var allSources []string
	var mu sync.Mutex

	// METHOD 6 — REDIRECT EXTRACTION
	// Follow the URL to see where it leads (e.g., bit.ly -> actual player)
	finalURL, err := FollowRedirects(targetURL)
	if err != nil {
		log.Printf("[FINDER][METHOD 6] Redirect failed for %s: %v", targetURL, err)
		finalURL = targetURL
	}

	html, err := FetchHTML(finalURL)
	if err != nil {
		log.Printf("[FINDER] Failed to fetch HTML for %s: %v", finalURL, err)
		return nil
	}

	// METHOD 7 — EMBED PROVIDER EXTRACTION
	// Look for common embed providers inside this page
	embeds := ExtractEmbeds(html)
	mu.Lock()
	allSources = append(allSources, embeds...)
	mu.Unlock()

	// METHOD 2 — IFRAME EXTRACTION
	// Extract iframes and recursively scan them for players or direct links
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

	// METHOD 1 — HTML PARSING
	// Look for <video>, <source> tags and direct extensions in HTML
	htmlSources := ExtractVideoSources(html)
	mu.Lock()
	allSources = append(allSources, htmlSources...)
	mu.Unlock()

	// METHOD 3 — JAVASCRIPT VARIABLE PARSING
	// Parse JS variables for file: "..." or sources: [...]
	jsSources := ExtractJSVariables(html)
	mu.Lock()
	allSources = append(allSources, jsSources...)
	mu.Unlock()

	// METHOD 4 — PLAYER JSON CONFIG
	// Parse large JSON blocks that look like player configurations
	jsonSources := ExtractJSONConfig(html)
	mu.Lock()
	allSources = append(allSources, jsonSources...)
	mu.Unlock()

	// METHOD 5 — NETWORK DISCOVERY (Part 1: API/AJAX calls)
	// Some sites fetch their video link via a separate AJAX request
	networkEndpoints := ExtractNetworkDiscovery(html)
	for _, endpoint := range networkEndpoints {
		wg.Add(1)
		go func(ep string) {
			defer wg.Done()
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

	// METHOD 8 — JSON-LD EXTRACTION (Bonus Method)
	jsonLDSources := ExtractJSONLD(html)
	mu.Lock()
	allSources = append(allSources, jsonLDSources...)
	mu.Unlock()

	wg.Wait()

	return allSources
}

func (f *UniversalFinder) UniqueSources(sources []string) []string {
	keys := make(map[string]bool)
	var list []string
	for _, entry := range sources {
		if !f.IsValidVideo(entry) {
			continue
		}

		normalized := f.NormalizeURL(entry)
		if normalized == "" {
			continue
		}

		if _, value := keys[normalized]; !value {
			keys[normalized] = true
			list = append(list, entry)
			log.Printf("[FINDER] Valid Source Discovered: %s", entry)
		}
	}
	return list
}

func (f *UniversalFinder) NormalizeURL(rawURL string) string {
	u, err := url.Parse(rawURL)
	if err != nil {
		return strings.ToLower(rawURL)
	}

	// Remove common tracking and session parameters that change on every request
	// but keep essential ones like 'sig' or 'hash' if they exist.
	q := u.Query()
	paramsToRemove := []string{"token", "expires", "ip", "v", "key", "t", "st", "e", "verify"}
	for _, p := range paramsToRemove {
		q.Del(p)
	}

	u.RawQuery = q.Encode()
	u.Fragment = ""

	return strings.ToLower(u.String())
}

func (f *UniversalFinder) IsValidVideo(url string) bool {
	lower := strings.ToLower(url)
	validExts := []string{".m3u8", ".mp4", ".mpd", ".webm", ".mkv", ".f4v", ".flv", "/manifest/", "/playlist/", "/get_video/", "/stream/"}

	// Check for common video extensions or keywords
	for _, ext := range validExts {
		if strings.Contains(lower, ext) {
			return true
		}
	}

	// Check for direct embed patterns that we consider "valid enough" to return to frontend
	embedMarkers := []string{"vidsrc.to", "2embed.cc", "multiembed.mov", "vidlink.pro", "superembed.stream"}
	for _, marker := range embedMarkers {
		if strings.Contains(lower, marker) {
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
	return "720p" // Default to 720p if unknown
}
