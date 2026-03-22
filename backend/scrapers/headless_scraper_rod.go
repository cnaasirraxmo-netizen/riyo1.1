package scrapers

import (
	"context"
	"fmt"
	"os"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/proto"
)

type HeadlessScraperRod struct {
}

func NewHeadlessScraperRod() *HeadlessScraperRod {
	return &HeadlessScraperRod{}
}

func (s *HeadlessScraperRod) ExtractSources(ctx context.Context, targetURL string) []string {
	if os.Getenv("DISABLE_BROWSER") == "true" {
		log.Printf("[ROD] Browser extraction skipped (DISABLE_BROWSER=true)")
		return []string{}
	}

	browser := rod.New().MustConnect()
	defer browser.MustClose()

	page := browser.MustPage("")
	defer page.MustClose()

	var discovered []string
	var mu sync.Mutex

	// 1. Stealth and Optimization
	_ = page.SetUserAgent(&proto.NetworkSetUserAgentOverride{
		UserAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
	})

	// Enable network interception
	router := page.HijackRequests()
	router.MustAdd("*", func(ctx *rod.Hijack) {
		reqURL := ctx.Request.URL().String()
		if s.isVideoSource(reqURL) {
			mu.Lock()
			discovered = append(discovered, reqURL)
			mu.Unlock()
		}

		// Block heavy/unnecessary resources to speed up load
		resType := ctx.Request.Type()
		if resType == proto.NetworkResourceTypeImage ||
		   resType == proto.NetworkResourceTypeFont ||
		   resType == proto.NetworkResourceTypeStylesheet {
			ctx.Response.Fail(proto.NetworkErrorReasonBlockedByClient)
			return
		}

		ctx.ContinueRequest(&proto.FetchContinueRequest{})
	})
	go router.Run()
	defer router.Stop()

	// 2. Navigation with Timeout
	err := rod.Try(func() {
		page.Timeout(15 * time.Second).MustNavigate(targetURL)
		page.Timeout(10 * time.Second).MustWaitLoad()

		// 3. Interaction - Look for play buttons in main page and iframes
		s.triggerPlay(page)

		// Wait a bit for network requests to trigger
		time.Sleep(5 * time.Second)
	})

	if err != nil {
		log.Printf("[ROD] Error scraping %s: %v", targetURL, err)
	}

	return s.uniqueSources(discovered)
}

func (s *HeadlessScraperRod) triggerPlay(page *rod.Page) {
	// Try to click various play button selectors
	selectors := []string{"#play", ".play", ".vjs-big-play-button", "button[aria-label='Play']", ".jw-display-icon-container"}
	for _, sel := range selectors {
		if el, err := page.Element(sel); err == nil && el != nil {
			_ = el.Click(proto.InputMouseButtonLeft, 1)
		}
	}

	// Also try to find iframes and look for play buttons there (Network interception handles nested naturally)
	iframes, _ := page.Elements("iframe")
	for _, iframe := range iframes {
		if content, err := iframe.Frame(); err == nil {
			for _, sel := range selectors {
				if el, err := content.Element(sel); err == nil && el != nil {
					_ = el.Click(proto.InputMouseButtonLeft, 1)
				}
			}
		}
	}
}

func (s *HeadlessScraperRod) isVideoSource(url string) bool {
	lower := strings.ToLower(url)
	return strings.Contains(lower, ".m3u8") ||
		strings.Contains(lower, ".mpd") ||
		strings.Contains(lower, ".mp4") ||
		strings.Contains(lower, "/playlist/") ||
		strings.Contains(lower, "/manifest/")
}

func (s *HeadlessScraperRod) uniqueSources(sources []string) []string {
	keys := make(map[string]bool)
	var list []string
	for _, entry := range sources {
		if _, value := keys[entry]; !value && entry != "" {
			keys[entry] = true
			list = append(list, entry)
			fmt.Printf("[ROD] Discovered Video Link: %s\n", entry)
		}
	}
	return list
}
