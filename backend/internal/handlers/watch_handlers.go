package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"encoding/base64"
	"sort"
	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/services"
	"github.com/riyobox/backend/providers"
)

var (
	embedSvc   = services.NewEmbedService()
	scraperSvc = services.NewScraperService()
	tmdbProv   = providers.NewTMDbProvider()
)

type WatchResponse struct {
	TMDBID    int                      `json:"tmdb_id"`
	Sources   []services.ScrapedSource `json:"sources"`
	CachedAt  time.Time                `json:"cached_at"`
	ExpiresAt time.Time                `json:"expires_at"`
}

func WatchMovie(c *gin.Context) {
	tmdbIDStr := c.Query("tmdb_id")
	if tmdbIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "tmdb_id is required"})
		return
	}

	tmdbID, err := strconv.Atoi(tmdbIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "invalid tmdb_id format"})
		return
	}

	data, err := getWatchData(tmdbID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": err.Error()})
		return
	}

	resp, ok := data.(WatchResponse)
	if !ok {
		// Handle cases where cache might have different structure (shouldn't happen with proper cleanup)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "cache data inconsistency"})
		return
	}
	proxiedSources := proxySources(resp.Sources, c.Request.Host)

	bestURL := ""
	bestSource := services.ScrapedSource{}
	if len(proxiedSources) > 0 {
		bestSource = proxiedSources[0]
		bestURL = bestSource.URL
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"tmdb_id":  resp.TMDBID,
		"url":      bestURL,
		"quality":  bestSource.Quality,
		"type":     bestSource.Type,
		"provider": bestSource.Provider,
		"note":     "HLS compatible URL with CORS support",
	})
}

func WatchAllSources(c *gin.Context) {
	tmdbIDStr := c.Query("tmdb_id")
	if tmdbIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "tmdb_id is required"})
		return
	}

	tmdbID, err := strconv.Atoi(tmdbIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "invalid tmdb_id format"})
		return
	}

	data, err := getWatchData(tmdbID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": err.Error()})
		return
	}

	resp, ok := data.(WatchResponse)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "cache data inconsistency"})
		return
	}
	resp.Sources = proxySources(resp.Sources, c.Request.Host)

	c.JSON(http.StatusOK, gin.H{"success": true, "data": resp})
}

func getWatchData(tmdbID int) (interface{}, error) {
	cacheKey := fmt.Sprintf("movie_watch_%d", tmdbID)

	return cache.GetOrSetCache(cacheKey, 24*time.Hour, func() (interface{}, error) {
		tmdbIDStr := strconv.Itoa(tmdbID)
		// 1. Generate Embed URLs
		embeds := embedSvc.GenerateEmbedURLs(tmdbIDStr)

		// 2. Scrape each URL
		var allSources []services.ScrapedSource
		var wg sync.WaitGroup
		var mu sync.Mutex

		// Limit concurrent scraping of providers
		sem := make(chan struct{}, 2)

		for _, e := range embeds {
			wg.Add(1)
			go func(u, prov string) {
				defer wg.Done()
				select {
				case sem <- struct{}{}:
					defer func() { <-sem }()
				case <-time.After(30 * time.Second): // Global safety timeout
					return
				}

				sources, err := scraperSvc.Scrape(u)
				if err == nil {
					mu.Lock()
					for _, s := range sources {
						s.Provider = prov
						allSources = append(allSources, s)
					}
					mu.Unlock()
				}
			}(e.URL, e.Provider)
		}
		wg.Wait()

		// 3. Prioritize Sources
		ranked := rankSources(allSources)

		return WatchResponse{
			TMDBID:    tmdbID,
			Sources:   ranked,
			CachedAt:  time.Now(),
			ExpiresAt: time.Now().Add(24 * time.Hour),
		}, nil
	})
}

func proxySources(sources []services.ScrapedSource, host string) []services.ScrapedSource {
	baseURL := GetBaseURL(host)
	proxied := make([]services.ScrapedSource, len(sources))
	for i, s := range sources {
		if s.Type == "embed" {
			proxied[i] = s
			continue
		}
		encodedURL := base64.URLEncoding.EncodeToString([]byte(s.URL))
		s.URL = fmt.Sprintf("%s/api/v1/stream/%s", baseURL, encodedURL)
		proxied[i] = s
	}
	return proxied
}

func RefreshMovieCache(c *gin.Context) {
	tmdbIDStr := c.Query("tmdb_id")
	if tmdbIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "tmdb_id is required"})
		return
	}

	tmdbID, err := strconv.Atoi(tmdbIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "invalid tmdb_id format"})
		return
	}
	cacheKey := fmt.Sprintf("movie_watch_%d", tmdbID)

	// Rate limiting: Force refresh check (max 2/day)
	refreshKey := fmt.Sprintf("refresh_count_%d", tmdbID)
	refreshCountBytes, err := cache.RedisClient.Get(cache.Ctx, refreshKey).Bytes()
	refreshCount := 0
	if err == nil {
		refreshCount, _ = strconv.Atoi(string(refreshCountBytes))
	}

	if refreshCount >= 2 {
		c.JSON(http.StatusTooManyRequests, gin.H{"success": false, "message": "Refresh limit reached (max 2/day)"})
		return
	}

	// Invalidate and increment refresh count
	cache.InvalidateCache(cacheKey)
	cache.RedisClient.Incr(cache.Ctx, refreshKey)
	cache.RedisClient.Expire(cache.Ctx, refreshKey, 24*time.Hour)

	WatchMovie(c)
}

func rankSources(sources []services.ScrapedSource) []services.ScrapedSource {
	// Quality > Type (HLS/Dash > MP4)
	qualityMap := map[string]int{
		"4K":    5,
		"1080p": 4,
		"720p":  3,
		"480p":  2,
		"360p":  1,
	}
	typeMap := map[string]int{
		"hls":  3,
		"dash": 2,
		"mp4":  1,
	}

	sort.Slice(sources, func(i, j int) bool {
		scoreI := qualityMap[sources[i].Quality]*10 + typeMap[sources[i].Type]
		scoreJ := qualityMap[sources[j].Quality]*10 + typeMap[sources[j].Type]
		return scoreI > scoreJ
	})

	return sources
}

func SearchTMDB(c *gin.Context) {
	q := c.Query("q")
	if q == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Query required"})
		return
	}

	results, err := tmdbProv.SearchMovies(q)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": results})
}

func GetEmbeds(c *gin.Context) {
	tmdbID := c.Param("tmdb_id")
	embeds := embedSvc.GenerateEmbedURLs(tmdbID)
	c.JSON(http.StatusOK, gin.H{"success": true, "embed_urls": embeds})
}

func ScrapeEmbed(c *gin.Context) {
	url := c.Query("url")
	sources, err := scraperSvc.Scrape(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "sources": sources})
}
