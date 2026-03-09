package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/handlers"
	"github.com/riyobox/backend/internal/middleware"
	"github.com/riyobox/backend/internal/services"
	"github.com/riyobox/backend/internal/utils"
)

func main() {
	godotenv.Load()

	if os.Getenv("NODE_ENV") == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	db.ConnectDB()
	utils.InitR2()

	// Initialize Video Pipeline
	videoOrchestrator := services.NewVideoOrchestrator()
	handlers.VideoOrchestrator = videoOrchestrator
	videoWorker := services.NewVideoWorker(videoOrchestrator, utils.R2Client, utils.GetBucketName())
	videoWorker.Start()

	r := gin.Default()

	// Support large file uploads (up to 1 GiB)
	r.MaxMultipartMemory = 1 << 30

	// CORS
	corsConfig := cors.DefaultConfig()
	if os.Getenv("NODE_ENV") == "production" {
		origins := []string{}
		if front := os.Getenv("FRONTEND_URL"); front != "" { origins = append(origins, front) }
		if admin := os.Getenv("ADMIN_URL"); admin != "" { origins = append(origins, admin) }

		if len(origins) > 0 {
			corsConfig.AllowOrigins = origins
		} else {
			corsConfig.AllowAllOrigins = true
		}
	} else {
		corsConfig.AllowAllOrigins = true
	}
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	corsConfig.AllowHeaders = []string{"Content-Type", "Authorization"}
	r.Use(cors.New(corsConfig))

	// Routes
	auth := r.Group("/auth")
	{
		auth.POST("/register", handlers.Register)
		auth.POST("/login", handlers.Login)
	}

	movies := r.Group("/movies")
	movies.Use(middleware.Protect())
	{
		movies.GET("/", handlers.GetMovies)
		movies.GET("/coming-soon", handlers.GetComingSoonMovies)
		movies.GET("/:id", handlers.GetMovieByID)
	}

	config := r.Group("/config")
	{
		config.GET("/categories", handlers.GetCategories)
		config.POST("/categories", handlers.CreateCategory)
		config.PUT("/categories/:id", handlers.UpdateCategory)
		config.DELETE("/categories/:id", handlers.DeleteCategory)
		config.POST("/categories/reorder", handlers.ReorderCategories)

		config.GET("/home-sections", handlers.GetHomeSections)
		config.POST("/home-sections", handlers.CreateHomeSection)
		config.PUT("/home-sections/:id", handlers.UpdateHomeSection)
		config.DELETE("/home-sections/:id", handlers.DeleteHomeSection)
		config.POST("/home-sections/reorder", handlers.ReorderHomeSections)
	}

	users := r.Group("/users")
	users.Use(middleware.Protect())
	{
		users.GET("/profile", handlers.GetProfile)
		users.POST("/watchlist/:movieId", handlers.ToggleWatchlist)
		users.POST("/notify-me/:movieId", handlers.ToggleNotifyMe)
		users.GET("/settings", handlers.GetUserSettings)
		users.PUT("/settings", handlers.UpdateUserSettings)
	}

	r.GET("/system-config", handlers.GetSystemConfig)

	admin := r.Group("/admin")
	admin.Use(middleware.Protect(), middleware.AdminOnly())
	{
		admin.POST("/movies", handlers.AdminCreateMovie)
		admin.GET("/movies", handlers.AdminGetMovies)
		admin.PUT("/movies/:id/publish", handlers.AdminPublishMovie)
		admin.DELETE("/movies/:id", handlers.AdminDeleteMovie)
		admin.GET("/users", handlers.AdminGetUsers)
		admin.PUT("/system-config", handlers.AdminUpdateSystemConfig)
	}

	upload := r.Group("/upload")
	upload.Use(middleware.Protect(), middleware.AdminOnly())
	{
		upload.POST("/", handlers.UploadFile)
		upload.POST("/by-url", handlers.UploadByURL)
		upload.GET("/", handlers.ListFiles)
		upload.DELETE("/:key", handlers.DeleteFile)
		upload.GET("/signed-url/:key", handlers.GetSignedURL)
	}

	r.GET("/", func(c *gin.Context) {
		r2Configured := os.Getenv("R2_ACCESS_KEY_ID") != "" && os.Getenv("R2_SECRET_ACCESS_KEY") != "" && os.Getenv("R2_BUCKET_NAME") != ""
		c.JSON(http.StatusOK, gin.H{
			"message":   "Riyo API is running (Go version)...",
			"status":    "Operational",
			"database":  "Connected", // Simplified
			"storage":   map[bool]string{true: "R2 Configured", false: "R2 Missing Configuration"}[r2Configured],
			"timestamp": time.Now(),
		})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "5000"
	}

	log.Printf("Server running on port %s", port)
	r.Run(":" + port)
}
