package services

import (
	"fmt"
	"net/http"
	"time"
)

type EmbedURL struct {
	Provider string `json:"provider"`
	URL      string `json:"url"`
}

type EmbedService struct {
	client *http.Client
}

func NewEmbedService() *EmbedService {
	return &EmbedService{
		client: &http.Client{
			Timeout: 5 * time.Second,
		},
	}
}

func (s *EmbedService) GenerateEmbedURLs(tmdbID string) []EmbedURL {
	providers := []struct {
		Name    string
		Pattern string
	}{
		{"VidSrc.xyz", "https://vidsrc.xyz/embed/movie/%s"},
		{"Embed.su", "https://embed.su/embed/movie/%s"},
		{"2Embed", "https://2embed.cc/embed/movie/%s"},
		{"VidLink", "https://vidlink.pro/movie/%s"},
		{"MultiEmbed", "https://multiembed.mov/?video_id=%s&tmdb=1"},
		{"VidSrc.to", "https://vidsrc.to/embed/movie/%s"},
		{"VidSrc.me", "https://vidsrc.me/embed/movie?tmdb=%s"},
	}

	var results []EmbedURL
	for _, p := range providers {
		url := fmt.Sprintf(p.Pattern, tmdbID)
		if s.ValidateURL(url) {
			results = append(results, EmbedURL{
				Provider: p.Name,
				URL:      url,
			})
		}
	}

	return results
}

func (s *EmbedService) ValidateURL(url string) bool {
	// For embed URLs, a simple HEAD request might not always work as they might require certain headers or JS
	// But the task says "Validate URL format before returning" which might just mean syntax or a basic reachability check.
	// I'll do a basic reachability check but many embed providers block HEAD/GET without proper headers.

	req, err := http.NewRequest("HEAD", url, nil)
	if err != nil {
		return false
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

	resp, err := s.client.Do(req)
	if err != nil {
		// Fallback to GET if HEAD is not allowed
		req.Method = "GET"
		resp, err = s.client.Do(req)
		if err != nil {
			return false
		}
	}
	defer resp.Body.Close()

	// Most embed providers return 200 even if movie is not found (they show an internal error page)
	// So we mostly check if the domain is up.
	return resp.StatusCode < 400
}
