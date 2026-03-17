package extraction

import (
	"time"
	"github.com/riyobox/backend/internal/models"
)

var headless = NewHeadlessScraper(45 * time.Second)

// ExtractAll is the main entry point to run all extractors on the provided HTML.
func ExtractAll(html string) []models.Source {
	return RecursiveExtract(html, 0)
}

// ExtractAllWithBrowser runs extraction including a headless browser pass on the target URL.
func ExtractAllWithBrowser(url string, html string) []models.Source {
	var sources []models.Source

	// Step 1: Headless browser pass (Intercept network requests)
	browserUrls := headless.ScrapeVideoURLs(url)
	for _, u := range browserUrls {
		sources = append(sources, models.Source{
			URL:     u,
			Quality: DetectQuality(u),
			Type:    detectType(u),
		})
	}

	// Step 2: Regular recursive extraction on the HTML
	sources = append(sources, RecursiveExtract(html, 0)...)

	return RemoveDuplicates(sources)
}

// RecursiveExtract runs all extraction modules on the HTML, supporting recursive iframe traversal.
func RecursiveExtract(html string, depth int) []models.Source {
	var sources []models.Source

	// Step 1: Run all direct HTML-based extractors
	sources = append(sources, ExtractHTML(html)...)
	sources = append(sources, ExtractJS(html)...)
	sources = append(sources, ExtractJSON(html)...)
	sources = append(sources, ExtractNetwork(html)...)
	sources = append(sources, ExtractRedirects(html)...)

	// Step 2: Handle recursive discovery (Iframes & Embeds)
	if depth < 3 { // Set depth limit for safe recursion
		sources = append(sources, FindSourcesFromIframes(html, depth)...)
		sources = append(sources, ExtractEmbeds(html)...)
	}

	return RemoveDuplicates(sources)
}
