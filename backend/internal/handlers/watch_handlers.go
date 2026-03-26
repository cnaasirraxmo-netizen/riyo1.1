package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/providers"
)

var (
	tmdbProv   = providers.NewTMDbProvider()
)

type WatchResponse struct {
	TMDBID    int                      `json:"tmdb_id"`
	Sources   []interface{}            `json:"sources"`
	CachedAt  time.Time                `json:"cached_at"`
	ExpiresAt time.Time                `json:"expires_at"`
}

func WatchMovie(c *gin.Context) {
	c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Scraping is disabled"})
}

func WatchAllSources(c *gin.Context) {
	c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Scraping is disabled"})
}

func RefreshMovieCache(c *gin.Context) {
	c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Scraping is disabled"})
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
	c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Scraping is disabled"})
}

func ScrapeEmbed(c *gin.Context) {
	c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Scraping is disabled"})
}
