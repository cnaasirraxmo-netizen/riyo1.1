package middleware

import (
	"strings"
	"github.com/gin-gonic/gin"
	"github.com/riyo/pkg/firebase"
	"github.com/riyo/pkg/auth"
	"net/http"
)

func AuthMiddleware(fbClient *firebase.Client, internalSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		idToken := strings.TrimPrefix(authHeader, "Bearer ")

		// Verify Firebase ID Token
		decodedToken, err := fbClient.VerifyIDToken(c.Request.Context(), idToken)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Firebase ID Token"})
			c.Abort()
			return
		}

		uid := decodedToken.UID
		role := "user"
		if admin, ok := decodedToken.Claims["admin"].(bool); ok && admin {
			role = "admin"
		}

		// Generate short-lived internal JWT
		internalToken, err := auth.GenerateInternalToken(uid, role, internalSecret)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate internal token"})
			c.Abort()
			return
		}

		// Inject headers for downstream services
		c.Request.Header.Set("X-Internal-Token", internalToken)
		c.Request.Header.Set("X-User-ID", uid)
		c.Request.Header.Set("X-User-Role", role)

		c.Next()
	}
}
