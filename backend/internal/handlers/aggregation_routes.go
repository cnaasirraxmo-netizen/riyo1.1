package handlers

import (
	"net/http/httptest"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/middleware"
)

func RegisterNewRoutes(r *gin.Engine) {
	api := r.Group("/api/v1")
	{
		api.GET("/home", middleware.Cache(cache.TrendingTTL), GetHome)
		api.GET("/search", middleware.Cache(cache.SearchTTL), SearchMovies)
		api.GET("/movie/:id/sources", middleware.Cache(cache.SourcesTTL), GetMovieSources)
		api.GET("/tv/:id/sources/:season/:episode", middleware.Cache(cache.SourcesTTL), GetTVSources)
		api.GET("/stream/:id", ProxyStream)
	}
}

func CreateTestContext(w *httptest.ResponseRecorder) (*gin.Context, *gin.Engine) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	c, _ := gin.CreateTestContext(w)
	return c, r
}
