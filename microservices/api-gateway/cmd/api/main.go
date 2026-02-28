package main

import (
	"log"
	"github.com/gin-gonic/gin"
	"github.com/riyo/api-gateway/config"
	"github.com/riyo/api-gateway/internal/handler"
	"github.com/riyo/api-gateway/internal/middleware"
	"github.com/riyo/pkg/firebase"
)

func main() {
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Could not load config: %v", err)
	}

	fbClient, err := firebase.NewFirebaseClient(cfg.FirebaseCredsFile)
	if err != nil {
		log.Printf("Warning: Firebase not initialized (check credentials): %v", err)
	}

	r := gin.Default()

	// Public routes
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "UP", "service": "api-gateway"})
	})

	// Protected routes
	v1 := r.Group("/v1")
	if fbClient != nil {
		v1.Use(middleware.AuthMiddleware(fbClient, cfg.InternalSecret))
	}

	// Microservices Proxies
	v1.Any("/users/*proxyPath", handler.ProxyHandler(cfg.UserServiceURL))
	v1.Any("/metadata/*proxyPath", handler.ProxyHandler(cfg.MetadataServiceURL))
	v1.Any("/auth-stream/*proxyPath", handler.ProxyHandler(cfg.StreamingAuthURL))
	v1.Any("/notifications/*proxyPath", handler.ProxyHandler(cfg.NotificationServiceURL))

	// Legacy Node.js CMS Proxy
	v1.Any("/cms/*proxyPath", handler.ProxyHandler(cfg.NodeJsServiceURL))

	log.Printf("API Gateway starting on port %s", cfg.Port)
	r.Run(":" + cfg.Port)
}
