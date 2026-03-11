package utils

import (
	"context"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

var RedisClient *redis.Client

func InitRedis() {
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "localhost:6379"
	}

	RedisClient = redis.NewClient(&redis.Options{
		Addr: redisURL,
	})
}

func GetCache(ctx context.Context, key string) (string, error) {
	if RedisClient == nil {
		return "", nil
	}
	return RedisClient.Get(ctx, key).Result()
}

func SetCache(ctx context.Context, key string, value string, expiration time.Duration) error {
	if RedisClient == nil {
		return nil
	}
	return RedisClient.Set(ctx, key, value, expiration).Err()
}

func InvalidateCache(ctx context.Context, key string) error {
	if RedisClient == nil {
		return nil
	}
	return RedisClient.Del(ctx, key).Err()
}
