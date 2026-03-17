package extraction

import (
	"regexp"
	"strings"
	"sync"
	"github.com/riyobox/backend/internal/models"
)

var (
	// Iframe tag src extraction
	iframeRe = regexp.MustCompile(`(?i)<iframe.*?src=["'](.*?)["']`)
)

// ExtractIframes finds iframe src URLs in the HTML.
func ExtractIframes(html string) []string {
	matches := iframeRe.FindAllStringSubmatch(html, -1)
	var urls []string
	unique := make(map[string]bool)

	for _, m := range matches {
		if len(m) > 1 {
			u := m[1]
			if strings.HasPrefix(u, "//") {
				u = "https:" + u
			}
			if !unique[u] {
				unique[u] = true
				urls = append(urls, u)
			}
		}
	}
	return urls
}

// FindSourcesFromIframes sends requests to all discovered iframe src URLs and returns all found video sources.
func FindSourcesFromIframes(html string, depth int) []models.Source {
	if depth > 4 { return nil } // Prevent infinite recursion

	var allSources []models.Source
	iframes := ExtractIframes(html)
	var mu sync.Mutex
	var wg sync.WaitGroup

	for _, iframeURL := range iframes {
		wg.Add(1)
		go func(url string) {
			defer wg.Done()
			iframeHTML, err := fetchHTML(url)
			if err == nil {
				// Recurse using a safe depth increment
				discovered := RecursiveExtract(iframeHTML, depth+1)
				mu.Lock()
				allSources = append(allSources, discovered...)
				mu.Unlock()
			}
		}(iframeURL)
	}

	wg.Wait()
	return allSources
}
