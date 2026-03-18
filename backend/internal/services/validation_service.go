package services

import (
	"net/http"
	"strings"
	"sync"
	"time"
	"github.com/riyobox/backend/internal/models"
)

// ValidateSources checks the status code and Content-Type of each found video URL.
func ValidateSources(sources []models.Source) []models.Source {
	var validated []models.Source
	var mu sync.Mutex
	var wg sync.WaitGroup

	client := &http.Client{Timeout: 10 * time.Second}

	for _, s := range sources {
		wg.Add(1)
		go func(src models.Source) {
			defer wg.Done()

			// Try HEAD first
			req, _ := http.NewRequest("HEAD", src.URL, nil)
			req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")

			resp, err := client.Do(req)
			if err != nil { return }
			defer resp.Body.Close()

			if resp.StatusCode == http.StatusOK {
				ct := strings.ToLower(resp.Header.Get("Content-Type"))
				if strings.Contains(ct, "video/") ||
					strings.Contains(ct, "application/x-mpegurl") ||
					strings.Contains(ct, "application/dash+xml") ||
					strings.Contains(ct, "application/octet-stream") ||
					strings.Contains(ct, "application/vnd.apple.mpegurl") {
					mu.Lock()
					validated = append(validated, src)
					mu.Unlock()
				}
			}
		}(s)
	}

	wg.Wait()
	return validated
}
