package scrapers

import (
	"strings"
	"sync"
)

type UniversalFinder struct{}

func NewUniversalFinder() *UniversalFinder {
	return &UniversalFinder{}
}

func (f *UniversalFinder) FindSources(url string) []string {
	return f.recursiveFind(url, 0)
}

func (f *UniversalFinder) recursiveFind(url string, depth int) []string {
	if depth > 2 {
		return nil
	}

	var allSources []string
	var mu sync.Mutex

	// 1. REDIRECT EXTRACTION (METHOD 6)
	finalURL, _ := FollowRedirects(url)
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
			discovered := f.recursiveFind(iframeURL, depth+1)
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
		if _, value := keys[entry]; !value && entry != "" {
			keys[entry] = true
			list = append(list, entry)
		}
	}
	return list
}

func (f *UniversalFinder) DetectQuality(url string) string {
	lowerURL := strings.ToLower(url)
	if strings.Contains(lowerURL, "2160") || strings.Contains(lowerURL, "4k") {
		return "4K"
	}
	if strings.Contains(lowerURL, "1080") {
		return "1080p"
	}
	if strings.Contains(lowerURL, "720") {
		return "720p"
	}
	if strings.Contains(lowerURL, "480") {
		return "480p"
	}
	return "720p"
}
