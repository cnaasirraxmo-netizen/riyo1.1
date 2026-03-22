package scrapers

import (
	"sync"
	"time"

	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/launcher"
)

// BrowserPool manages a pool of pages
type BrowserPool struct {
	browser *rod.Browser
	pages   chan *rod.Page
	mu      sync.Mutex
	maxSize int
}

var (
	poolInstance *BrowserPool
	poolOnce     sync.Once
)

// GetBrowserPool returns the singleton instance
func GetBrowserPool() *BrowserPool {
	poolOnce.Do(func() {
		// Launch Chromium with memory-friendly options
		l := launcher.New().
			Headless(true).
			Set("no-sandbox").
			Set("disable-setuid-sandbox").
			Set("disable-dev-shm-usage").
			Set("disable-accelerated-2d-canvas").
			Set("disable-gpu").
			Set("single-process").
			Set("no-zygote")

		url := l.MustLaunch()
		browser := rod.New().ControlURL(url).MustConnect()

		maxSize := 2 // keep pool small for memory
		poolInstance = &BrowserPool{
			browser: browser,
			pages:   make(chan *rod.Page, maxSize),
			maxSize: maxSize,
		}
	})
	return poolInstance
}

// GetPage retrieves a page from the pool or creates a temporary one
func (p *BrowserPool) GetPage(timeout time.Duration) (*rod.Page, func()) {
	select {
	case page := <-p.pages:
		// Return page to pool when done
		return page, func() { p.pages <- page }
	case <-time.After(timeout):
		// Timeout: create temporary page, close after use
		page := p.browser.MustPage("")
		return page, func() { page.MustClose() }
	}
}

// PutPage adds a page back to the pool safely
func (p *BrowserPool) PutPage(page *rod.Page) {
	select {
	case p.pages <- page:
		// successfully returned
	default:
		// pool full, close the page
		page.MustClose()
	}
}

// Close closes the browser and all pages
func (p *BrowserPool) Close() {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.browser != nil {
		close(p.pages) // close channel
		for page := range p.pages {
			page.MustClose()
		}
		p.browser.MustClose()
		p.browser = nil
	}
}
