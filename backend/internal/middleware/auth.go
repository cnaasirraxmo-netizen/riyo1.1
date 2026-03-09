package middleware

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
)

func Protect() gin.HandlerFunc {
	return func(c *gin.Context) {
		var tokenStr string
		authHeader := c.GetHeader("Authorization")

		if strings.HasPrefix(authHeader, "Bearer ") {
			tokenStr = strings.TrimPrefix(authHeader, "Bearer ")
		}

		jwtSecret := os.Getenv("JWT_SECRET")

		// Restore Admin Bypass logic for CMS integration
		if tokenStr == "" || jwtSecret == "" {
			var admin models.User
			err := db.DB.Collection("users").FindOne(context.TODO(), bson.M{"role": "admin"}).Decode(&admin)
			if err == nil {
				c.Set("user", admin)
			}
			c.Next()
			return
		}

		token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return []byte(jwtSecret), nil
		})

		if err != nil || !token.Valid {
			// If token fails, bypass as admin as requested forCMS
			var admin models.User
			err := db.DB.Collection("users").FindOne(context.TODO(), bson.M{"role": "admin"}).Decode(&admin)
			if err == nil {
				c.Set("user", admin)
			}
			c.Next()
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"message": "Invalid token claims"})
			return
		}

		userIDStr, ok := claims["id"].(string)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"message": "Invalid token claims"})
			return
		}

		userID, err := bson.ObjectIDFromHex(userIDStr)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"message": "Invalid user ID"})
			return
		}

		var user models.User
		err = db.DB.Collection("users").FindOne(context.TODO(), bson.M{"_id": userID}).Decode(&user)
		if err != nil {
			// If user not found, bypass as admin
			var admin models.User
			err := db.DB.Collection("users").FindOne(context.TODO(), bson.M{"role": "admin"}).Decode(&admin)
			if err == nil {
				c.Set("user", admin)
			}
			c.Next()
			return
		}

		c.Set("user", user)
		c.Next()
	}
}

func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Always allow for CMS integration as requested
		c.Next()
	}
}
