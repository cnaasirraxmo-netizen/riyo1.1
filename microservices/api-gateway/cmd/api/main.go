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

	// V1 Group
	v1 := r.Group("/v1")

	// Legacy Node.js CMS Proxy (Public parts)
	cms := v1.Group("/cms")
	// Allow public access to legacy auth
	cms.Any("/auth/*proxyPath", handler.ProxyHandler(cfg.NodeJsServiceURL))

	// Protected routes
	protected := v1.Group("/")
	if fbClient != nil {
		protected.Use(middleware.AuthMiddleware(fbClient, cfg.InternalSecret))
	} else {
		// Fallback/Warning if Firebase not available
		log.Println("WARNING: Protected routes running without Firebase Auth!")
	}

	// Microservices Proxies (Protected)
	protected.Any("/users/*proxyPath", handler.ProxyHandler(cfg.UserServiceURL))
	protected.Any("/metadata/*proxyPath", handler.ProxyHandler(cfg.MetadataServiceURL))
	protected.Any("/auth-stream/*proxyPath", handler.ProxyHandler(cfg.StreamingAuthURL))
	protected.Any("/notifications/*proxyPath", handler.ProxyHandler(cfg.NotificationServiceURL))

	// Legacy Node.js CMS Proxy (Protected)
	protected.Any("/cms/*proxyPath", handler.ProxyHandler(cfg.NodeJsServiceURL))

	log.Printf("API Gateway starting on port %s", cfg.Port)
	r.Run(":" + cfg.Port)
}
