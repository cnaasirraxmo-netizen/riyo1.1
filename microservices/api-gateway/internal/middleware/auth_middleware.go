package middleware

import (
	"context"
	"net/http"
	"strings"
	"github.com/gin-gonic/gin"
	"github.com/riyo/pkg/auth"
	"github.com/riyo/pkg/firebase"
	"github.com/riyo/pkg/response"
)

func AuthMiddleware(fbClient *firebase.Client, internalSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, response.Error("Unauthorized", "Missing authorization header"))
			return
		}

		idToken := strings.TrimSpace(strings.Replace(authHeader, "Bearer", "", 1))
		token, err := fbClient.VerifyIDToken(context.Background(), idToken)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, response.Error("Unauthorized", "Invalid token"))
			return
		}

		// Generate internal JWT for service-to-service communication
		internalToken, err := auth.GenerateInternalToken(token.UID, "user", internalSecret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, response.Error("Internal error", "Failed to generate internal token"))
			return
		}

		// Inject user info into headers for downstream services
		c.Request.Header.Set("X-User-ID", token.UID)
		c.Request.Header.Set("X-Internal-Token", internalToken)

		c.Next()
	}
}
