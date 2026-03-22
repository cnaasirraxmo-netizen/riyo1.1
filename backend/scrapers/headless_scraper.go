package scrapers

import (
	"context"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/chromedp/cdproto/network"
	"github.com/chromedp/chromedp"
)

type HeadlessScraper struct {
	timeout time.Duration
	retries int
}

func NewHeadlessScraper() *HeadlessScraper {
	return &HeadlessScraper{
		timeout: 45 * time.Second,
		retries: 2,
	}
}

func (s *HeadlessScraper) ExtractDynamicSources(url string) []string {
	var sources []string
	var err error

	for i := 0; i <= s.retries; i++ {
		sources, err = s.runExtraction(url)
		if err == nil && len(sources) > 0 {
			return sources
		}
		if i < s.retries {
			log.Printf("[HEADLESS] Retry %d for URL: %s", i+1, url)
			time.Sleep(time.Duration(i+1) * 2 * time.Second)
		}
	}

	if err != nil {
		log.Printf("[HEADLESS] Final error extracting %s: %v", url, err)
	}

	return sources
}

func (s *HeadlessScraper) runExtraction(targetURL string) ([]string, error) {
	// 1. Create context
	opts := append(chromedp.DefaultExecAllocatorOptions[:],
		chromedp.NoFirstRun,
		chromedp.NoDefaultBrowserCheck,
		chromedp.Headless,
		chromedp.NoSandbox,
		chromedp.Flag("disable-setuid-sandbox", true),
		chromedp.Flag("disable-dev-shm-usage", true),
		chromedp.Flag("single-process", true),
		chromedp.Flag("no-zygote", true),
		chromedp.UserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"),
	)

	allocCtx, cancel := chromedp.NewExecAllocator(context.Background(), opts...)
	defer cancel()

	ctx, cancel := chromedp.NewContext(allocCtx, chromedp.WithLogf(log.Printf))
	defer cancel()

	// Create a timeout
	ctx, cancel = context.WithTimeout(ctx, s.timeout)
	defer cancel()

	var mu sync.Mutex
	var discoveredSources []string

	// 2. Setup network interception
	chromedp.ListenTarget(ctx, func(ev interface{}) {
		switch e := ev.(type) {
		case *network.EventRequestWillBeSent:
			reqURL := e.Request.URL
			if s.isVideoSource(reqURL) {
				mu.Lock()
				discoveredSources = append(discoveredSources, reqURL)
				mu.Unlock()
			}
		case *network.EventResponseReceived:
			// Sometimes the URL is in the response headers or redirect
			resURL := e.Response.URL
			if s.isVideoSource(resURL) {
				mu.Lock()
				discoveredSources = append(discoveredSources, resURL)
				mu.Unlock()
			}
		}
	})

	// 3. Navigate and wait for some time for dynamic content
	err := chromedp.Run(ctx,
		network.Enable(),
		chromedp.Navigate(targetURL),
		// Wait for the page to be somewhat stable or for specific elements
		chromedp.Sleep(5*time.Second),
		// Trigger interactions that might load the player (play button, etc.)
		// This script searches the main document and all accessible iframes
		chromedp.Evaluate(`
			(function() {
				function clickPlay(doc) {
					const selectors = ['#play', '.play', '.vjs-big-play-button', 'button[aria-label="Play"]', '.jw-display-icon-container', '.vjs-play-control'];
					selectors.forEach(s => {
						const el = doc.querySelector(s);
						if (el) {
							console.log('Headless: Clicking play button:', s);
							el.click();
						}
					});

					// Recurse into iframes
					const iframes = doc.querySelectorAll('iframe');
					iframes.forEach(iframe => {
						try {
							if (iframe.contentDocument) {
								clickPlay(iframe.contentDocument);
							}
						} catch (e) {
							// Cross-origin iframe, we can't reach inside with JS
							// but network interception still works for its requests
						}
					});
				}
				clickPlay(document);
			})()
		`, nil),
		chromedp.Sleep(10*time.Second), // Allow time for network requests to fire after "play"
	)

	if err != nil {
		return nil, err
	}

	return s.uniqueSources(discoveredSources), nil
}

func (s *HeadlessScraper) isVideoSource(url string) bool {
	lower := strings.ToLower(url)
	// Filtering for common streaming manifests and direct files
	return strings.Contains(lower, ".m3u8") ||
		strings.Contains(lower, ".mpd") ||
		strings.Contains(lower, ".mp4") ||
		strings.Contains(lower, "/playlist.m3u8") ||
		strings.Contains(lower, "/manifest.mpd")
}

func (s *HeadlessScraper) uniqueSources(sources []string) []string {
	keys := make(map[string]bool)
	var list []string
	for _, entry := range sources {
		if _, value := keys[entry]; !value && entry != "" {
			keys[entry] = true
			list = append(list, entry)
			fmt.Printf("[HEADLESS] Discovered Video Link: %s\n", entry)
		}
	}
	return list
}
