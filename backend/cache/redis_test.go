package cache

import (
	"fmt"
	"testing"
	"time"
)

func TestRedisConnection(t *testing.T) {
	InitRedis()
	if RedisClient == nil {
		t.Skip("Redis not configured, skipping connection test")
	}

	err := RedisClient.Set(Ctx, "test_key", "test_value", 1*time.Minute).Err()
	if err != nil {
		t.Errorf("Failed to SET: %v", err)
	}

	val, err := RedisClient.Get(Ctx, "test_key").Result()
	if err != nil {
		t.Errorf("Failed to GET: %v", err)
	}

	if val != "test_value" {
		t.Errorf("Expected test_value, got %s", val)
	}

	fmt.Println("Redis SET/GET test passed!")
}
