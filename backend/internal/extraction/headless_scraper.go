package extraction

import (
	"context"
	"encoding/json"
	"strings"
	"sync"
	"time"

	"github.com/chromedp/cdproto/network"
	"github.com/chromedp/chromedp"
)

// HeadlessScraper uses a browser to extract video links that are loaded dynamically via JS or XHR.
type HeadlessScraper struct {
	timeout time.Duration
}

func NewHeadlessScraper(timeout time.Duration) *HeadlessScraper {
	return &HeadlessScraper{timeout: timeout}
}

// ScrapeVideoURLs navigates to a URL and captures all video-related network requests.
func (s *HeadlessScraper) ScrapeVideoURLs(targetURL string) []string {
	var urls []string
	var mu sync.Mutex

	// Configure browser options
	opts := append(chromedp.DefaultExecAllocatorOptions[:],
		chromedp.NoSandbox,
		chromedp.Headless,
		chromedp.Flag("disable-setuid-sandbox", true),
		chromedp.Flag("disable-dev-shm-usage", true),
		chromedp.Flag("disable-extensions", true),
		chromedp.Flag("blink-settings", "imagesEnabled=false"),
		chromedp.UserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"),
	)

	allocCtx, cancel := chromedp.NewExecAllocator(context.Background(), opts...)
	defer cancel()

	ctx, cancel := chromedp.NewContext(allocCtx)
	defer cancel()

	ctx, cancel = context.WithTimeout(ctx, s.timeout)
	defer cancel()

	// Set up request interception
	chromedp.ListenTarget(ctx, func(ev interface{}) {
		switch e := ev.(type) {
		case *network.EventRequestWillBeSent:
			reqURL := e.Request.URL
			if IsVideoURL(reqURL) {
				mu.Lock()
				urls = append(urls, reqURL)
				mu.Unlock()
			}
		}
	})

	// Perform the navigation and wait
	err := chromedp.Run(ctx,
		network.Enable(),
		chromedp.Navigate(targetURL),
		chromedp.Sleep(5*time.Second),
		// No WaitVisible to avoid blocking if no video tag appears immediately
	)

	if err != nil {
		// Even if error, return what we found
	}

	return s.deduplicateAndPrioritize(urls)
}

// ScrapeVideoURLsJSON returns the discovered URLs in a JSON string format.
func (s *HeadlessScraper) ScrapeVideoURLsJSON(targetURL string) (string, error) {
	urls := s.ScrapeVideoURLs(targetURL)
	data, err := json.Marshal(urls)
	if err != nil {
		return "[]", err
	}
	return string(data), nil
}

func (s *HeadlessScraper) deduplicateAndPrioritize(urls []string) []string {
	unique := make(map[string]bool)
	var m3u8s []string
	var others []string

	for _, u := range urls {
		if !unique[u] {
			unique[u] = true
			if strings.Contains(strings.ToLower(u), ".m3u8") {
				m3u8s = append(m3u8s, u)
			} else {
				others = append(others, u)
			}
		}
	}

	return append(m3u8s, others...)
}
