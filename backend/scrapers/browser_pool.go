package scrapers

import (
	"sync"
	"time"

	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/launcher"
)

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

func GetBrowserPool() *BrowserPool {
	poolOnce.Do(func() {
		// Setup launcher with stealth and performance options
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

		maxSize := 5
		poolInstance = &BrowserPool{
			browser: browser,
			pages:   make(chan *rod.Page, maxSize),
			maxSize: maxSize,
		}

		// Initialize pages
		for i := 0; i < maxSize; i++ {
			page := browser.MustPage("")
			poolInstance.pages <- page
		}
	})
	return poolInstance
}

func (p *BrowserPool) GetPage(timeout time.Duration) (*rod.Page, func()) {
	select {
	case page := <-p.pages:
		return page, func() {
			p.pages <- page
		}
	case <-time.After(timeout):
		// If pool is empty and timeout reached, create a temporary page
		// or return nil. For simplicity, we return a new one if possible.
		return p.browser.MustPage(""), func() {
			// Don't put back in channel if pool is full
		}
	}
}

func (p *BrowserPool) Close() {
	if p.browser != nil {
		p.browser.MustClose()
	}
}
