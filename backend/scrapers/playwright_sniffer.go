package scrapers

import (
	"fmt"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/playwright-community/playwright-go"
)

type MediaResource struct {
	URL      string `json:"url"`
	Type     string `json:"type"` // hls, dash, direct
	MimeType string `json:"mimeType"`
	Size     int64  `json:"size"`
}

type PlaywrightSniffer struct {
	pw *playwright.Playwright
}

var (
	snifferInstance *PlaywrightSniffer
	snifferOnce     sync.Once
)

func NewPlaywrightSniffer() *PlaywrightSniffer {
	snifferOnce.Do(func() {
		pw, err := playwright.Run()
		if err != nil {
			log.Printf("Failed to start playwright: %v", err)
			return
		}
		snifferInstance = &PlaywrightSniffer{pw: pw}
	})
	return snifferInstance
}

func (s *PlaywrightSniffer) Sniff(targetURL string, headless bool, cookies []playwright.OptionalCookie) ([]MediaResource, error) {
	if s.pw == nil {
		return nil, fmt.Errorf("playwright not initialized")
	}

	browser, err := s.pw.Chromium.Launch(playwright.BrowserTypeLaunchOptions{
		Headless: playwright.Bool(headless),
		Args: []string{
			"--no-sandbox",
			"--disable-setuid-sandbox",
			"--disable-dev-shm-usage",
			"--single-process",
			"--no-zygote",
		},
	})
	if err != nil {
		return nil, err
	}
	defer browser.Close()

	context, err := browser.NewContext(playwright.BrowserNewContextOptions{
		UserAgent: playwright.String("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"),
	})
	if err != nil {
		return nil, err
	}
	if len(cookies) > 0 {
		context.AddCookies(cookies)
	}

	page, err := context.NewPage()
	if err != nil {
		return nil, err
	}

	var mu sync.Mutex
	var resources []MediaResource

	// Monitor network traffic
	page.OnRequest(func(request playwright.Request) {
		url := request.URL()
		if s.isMedia(url) {
			mu.Lock()
			resources = append(resources, MediaResource{
				URL:  url,
				Type: s.detectType(url),
			})
			mu.Unlock()
			fmt.Printf("[SNIFFER] Detected Media: %s\n", url)
		}
	})

	// Mimic user interaction to trigger media loading (like 1DM)
	_, err = page.Goto(targetURL, playwright.PageGotoOptions{
		WaitUntil: playwright.WaitUntilStateNetworkidle,
		Timeout:   playwright.Float(30000),
	})
	if err != nil {
		log.Printf("Page navigation error: %v", err)
	}

	// Wait a bit more for dynamic loads
	time.Sleep(5 * time.Second)

	return s.uniqueResources(resources), nil
}

func (s *PlaywrightSniffer) isMedia(url string) bool {
	lower := strings.ToLower(url)
	return strings.Contains(lower, ".m3u8") ||
		strings.Contains(lower, ".mpd") ||
		strings.Contains(lower, ".mp4") ||
		strings.Contains(lower, ".mkv") ||
		strings.Contains(lower, ".webm") ||
		strings.Contains(lower, "/playlist/") ||
		strings.Contains(lower, "/manifest/")
}

func (s *PlaywrightSniffer) detectType(url string) string {
	lower := strings.ToLower(url)
	if strings.Contains(lower, ".m3u8") || strings.Contains(lower, "playlist") {
		return "hls"
	}
	if strings.Contains(lower, ".mpd") || strings.Contains(lower, "manifest") {
		return "dash"
	}
	return "direct"
}

func (s *PlaywrightSniffer) uniqueResources(res []MediaResource) []MediaResource {
	keys := make(map[string]bool)
	var list []MediaResource
	for _, entry := range res {
		if _, value := keys[entry.URL]; !value {
			keys[entry.URL] = true
			list = append(list, entry)
		}
	}
	return list
}
