package middleware

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"github.com/riyo/pkg/auth"
	"github.com/riyo/pkg/response"
)

func InternalAuthMiddleware(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("X-Internal-Token")
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, response.Error("Unauthorized", "Missing internal token"))
			return
		}

		claims, err := auth.VerifyInternalToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, response.Error("Unauthorized", "Invalid internal token"))
			return
		}

		// Ensure the UID in header matches the UID in the token (redundant but safe)
		headerUID := c.GetHeader("X-User-ID")
		if headerUID != "" && claims.UID != headerUID {
			c.AbortWithStatusJSON(http.StatusForbidden, response.Error("Forbidden", "Token UID mismatch"))
			return
		}

		c.Set("uid", claims.UID)
		c.Set("role", claims.Role)
		c.Next()
	}
}
