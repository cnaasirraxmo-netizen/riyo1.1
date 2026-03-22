package utils

import (
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/v2/bson"
)

func GenerateToken(id bson.ObjectID) (string, error) {
	return GenerateTokenWithDuration(id, time.Hour)
}

func GenerateTokenWithDuration(id bson.ObjectID, duration time.Duration) (string, error) {
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		return "", errors.New("JWT_SECRET is missing from environment variables")
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"id":  id.Hex(),
		"exp": time.Now().Add(duration).Unix(),
	})

	return token.SignedString([]byte(jwtSecret))
}
