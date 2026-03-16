package handlers

import (
	"net/http/httptest"

	"github.com/gin-gonic/gin"
)

func RegisterNewRoutes(r *gin.Engine) {
	api := r.Group("/api/v1")
	{
		api.GET("/home", GetHome)
		api.GET("/search", SearchMovies)
		api.GET("/movie/:id/sources", GetMovieSources)
		api.GET("/tv/:id/sources/:season/:episode", GetTVSources)
	}
}

func CreateTestContext(w *httptest.ResponseRecorder) (*gin.Context, *gin.Engine) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	c, _ := gin.CreateTestContext(w)
	return c, r
}
