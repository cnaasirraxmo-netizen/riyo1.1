package handlers

import (
	"net/http/httptest"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/middleware"
)

func RegisterNewRoutes(r *gin.Engine) {
	api := r.Group("/api/v1")
	{
		api.GET("/home", middleware.Cache(6*time.Hour), GetHome)
		api.GET("/search", middleware.Cache(1*time.Hour), SearchMovies)
		api.GET("/movie/:id/sources", middleware.Cache(1*time.Hour), GetMovieSources)
		api.GET("/tv/:id/sources/:season/:episode", middleware.Cache(1*time.Hour), GetTVSources)
		api.GET("/stream/:id", ProxyStream)
		api.GET("/kids/home", middleware.Cache(12*time.Hour), GetKidsHome)
		api.POST("/analytics/usage", LogUsage)
		api.POST("/movies/:id/reviews", AddReview)
		api.POST("/extract", SniffMedia)
	}
}

func CreateTestContext(w *httptest.ResponseRecorder) (*gin.Context, *gin.Engine) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	c, _ := gin.CreateTestContext(w)
	return c, r
}
