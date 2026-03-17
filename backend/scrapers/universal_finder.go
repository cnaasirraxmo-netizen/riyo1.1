package scrapers

import (
	"strings"
	"sync"
	"time"
)

type UniversalFinder struct {
	headless *HeadlessScraper
}

func NewUniversalFinder() *UniversalFinder {
	return &UniversalFinder{
		headless: NewHeadlessScraper(30 * time.Second),
	}
}

// FindSources is the main entry point for the recursive extraction process.
func (f *UniversalFinder) FindSources(url string) []string {
	return f.recursiveFind(url, 0)
}

// recursiveFind implements the core extraction logic, traversing iframes up to depth 4.
func (f *UniversalFinder) recursiveFind(url string, depth int) []string {
	if depth > 4 {
		return nil
	}

	var allSources []string
	var mu sync.Mutex

	// STEP 1: FOLLOW REDIRECTS (Method 6)
	// Some providers use intermediate redirect pages to hide their true player URLs.
	finalURL, _ := FollowRedirects(url)
	html, err := FetchHTML(finalURL)
	if err != nil {
		return nil
	}

	// STEP 2: EMBED PROVIDER EXTRACTION (Method 7)
	// Identify and extract other embed links within the current page.
	embeds := ExtractEmbeds(html)
	mu.Lock()
	allSources = append(allSources, embeds...)
	mu.Unlock()

	// STEP 3: IFRAME EXTRACTION (Method 2)
	// Recursively discover sources from nested iframes.
	iframes := ExtractIframes(html)
	var wg sync.WaitGroup
	for _, iframe := range iframes {
		wg.Add(1)
		go func(iframeURL string) {
			defer wg.Done()
			discovered := f.recursiveFind(iframeURL, depth+1)
			mu.Lock()
			allSources = append(allSources, discovered...)
			mu.Unlock()
		}(iframe)
	}

	// STEP 4: HTML PARSING (Method 1)
	// Scan the page for <video>, <source>, and data-video-url tags.
	htmlSources := ExtractVideoSources(html)
	mu.Lock()
	allSources = append(allSources, htmlSources...)
	mu.Unlock()

	// STEP 5: JAVASCRIPT VARIABLE PARSING (Method 3)
	// Look for variables like 'hls_url', 'stream_url', etc. in <script> tags.
	jsSources := ExtractJSVariables(html)
	mu.Lock()
	allSources = append(allSources, jsSources...)
	mu.Unlock()

	// STEP 6: PLAYER CONFIG PARSING (Method 4)
	// Parse JSON configuration objects (common in JWPlayer and Video.js).
	jsonSources := ExtractJSONConfig(html)
	mu.Lock()
	allSources = append(allSources, jsonSources...)
	mu.Unlock()

	// STEP 7: NETWORK REQUEST DISCOVERY (Method 5)
	// Identify API endpoints that the player might call to fetch its stream.
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

	// STEP 8: HEADLESS BROWSER SCRAPING (Method 8)
	// Fallback to browser for heavily JS-dependent sites
	if depth == 0 { // Only run headless for the root URL to avoid infinite browser loops
		headlessSources := f.headless.ScrapeVideoURLs(url)
		mu.Lock()
		allSources = append(allSources, headlessSources...)
		mu.Unlock()
	}

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
		if _, value := keys[entry]; !value && entry != "" {
			keys[entry] = true
			list = append(list, entry)
		}
	}
	return list
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
