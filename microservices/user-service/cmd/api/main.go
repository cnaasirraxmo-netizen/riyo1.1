package main

import (
	"fmt"
	"log"
	"github.com/gin-gonic/gin"
	"github.com/riyo/user-service/config"
	"github.com/riyo/user-service/internal/delivery/http"
	"github.com/riyo/user-service/internal/domain"
	"github.com/riyo/user-service/internal/middleware"
	"github.com/riyo/user-service/internal/repository"
	"github.com/riyo/user-service/internal/usecase"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Could not load config: %v", err)
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		cfg.DBHost, cfg.DBUser, cfg.DBPass, cfg.DBName, cfg.DBPort)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Auto Migration
	db.AutoMigrate(&domain.User{})

	userRepo := repository.NewPostgresUserRepository(db)
	userUsecase := usecase.NewUserUsecase(userRepo)

	r := gin.Default()

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "UP"})
	})

	// Apply Internal Auth Middleware to all API routes
	apiRoutes := r.Group("/")
	apiRoutes.Use(middleware.InternalAuthMiddleware(cfg.InternalSecret))

	http.NewUserHandler(apiRoutes, userUsecase)

	log.Printf("User Service starting on port %s", cfg.Port)
	r.Run(":" + cfg.Port)
}
