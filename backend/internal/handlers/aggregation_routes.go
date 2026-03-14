package handlers

import (
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
