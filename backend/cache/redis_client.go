package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/klauspost/compress/zstd"
	"github.com/redis/go-redis/v9"
)

var (
	RedisClient *redis.Client
	Ctx         = context.Background()
	encoder, _  = zstd.NewWriter(nil)
	decoder, _  = zstd.NewReader(nil)
)

func InitRedis() {
	urls := []string{
		os.Getenv("REDIS_URL"),
		os.Getenv("REDIS_PUBLIC_URL"),
	}

	for _, redisURL := range urls {
		if redisURL == "" {
			continue
		}

		opts, err := redis.ParseURL(redisURL)
		if err != nil {
			log.Printf("Failed to parse Redis URL %s: %v", redisURL, err)
			continue
		}

		if tryConnect(opts, "URL") {
			return
		}
	}

	host := os.Getenv("REDISHOST")
	port := os.Getenv("REDISPORT")
	user := os.Getenv("REDISUSER")
	pass := os.Getenv("REDISPASSWORD")

	if host != "" && port != "" {
		opts := &redis.Options{
			Addr:     fmt.Sprintf("%s:%s", host, port),
			Username: user,
			Password: pass,
		}
		if tryConnect(opts, "Host/Port") {
			return
		}
	}

	log.Println("Redis environment variables not set or all connections failed, caching disabled")
}

func tryConnect(opts *redis.Options, source string) bool {
	// Connection pooling and optimization
	opts.PoolSize = 100
	opts.MinIdleConns = 10
	opts.DialTimeout = 5 * time.Second
	opts.ReadTimeout = 3 * time.Second
	opts.WriteTimeout = 3 * time.Second
	opts.MaxRetries = 3
	opts.MinRetryBackoff = 8 * time.Millisecond
	opts.MaxRetryBackoff = 512 * time.Millisecond

	if dbStr := os.Getenv("REDIS_DB"); dbStr != "" {
		if db, err := strconv.Atoi(dbStr); err == nil {
			opts.DB = db
		}
	}

	client := redis.NewClient(opts)
	_, err := client.Ping(Ctx).Result()
	if err != nil {
		log.Printf("Warning: Redis connection via %s failed: %v", source, err)
		client.Close()
		return false
	}

	RedisClient = client
	log.Printf("Connected to Redis successfully via %s", source)
	return true
}

func GetOrSetCache(key string, ttl time.Duration, fetchFunc func() (interface{}, error)) (interface{}, error) {
	if RedisClient == nil {
		return fetchFunc()
	}

	start := time.Now()

	// 1. Check Redis for the key
	val, err := RedisClient.Get(Ctx, key).Bytes()
	if err == nil {
		// Check if data is compressed (zstd magic number is \x28\xb5\x2f\xfd)
		var decompressed []byte = val
		if len(val) > 4 && val[0] == 0x28 && val[1] == 0xb5 && val[2] == 0x2f && val[3] == 0xfd {
			decompressed, err = decoder.DecodeAll(val, nil)
			if err != nil {
				log.Printf("[CACHE ERROR] Decompression failed for %s: %v", key, err)
				return fetchFunc()
			}
		}

		var data interface{}
		if err := json.Unmarshal(decompressed, &data); err == nil {
			// Cache Hit
			latency := time.Since(start)
			log.Printf("[CACHE HIT] Key: %s | Latency: %v", key, latency)
			return data, nil
		}
		log.Printf("[CACHE ERROR] Failed to process cached data for %s: %v", key, err)
	}

	// 2. Cache Miss
	result, err := fetchFunc()
	if err != nil {
		latency := time.Since(start)
		log.Printf("[CACHE MISS/ERROR] Key: %s | Fetch Error: %v | Latency: %v", key, err, latency)
		return nil, err
	}

	latency := time.Since(start)
	log.Printf("[CACHE MISS] Key: %s | Latency: %v", key, latency)

	// 3. Store result in Redis
	go func() {
		data, err := json.Marshal(result)
		if err != nil {
			return
		}

		// Compress large responses (> 1KB)
		var finalData []byte = data
		if len(data) > 1024 {
			finalData = encoder.EncodeAll(data, nil)
		}

		err = RedisClient.Set(Ctx, key, finalData, ttl).Err()
		if err != nil {
			log.Printf("[CACHE SET ERROR] Key: %s | Error: %v", key, err)
		}
	}()

	return result, nil
}

func InvalidateCache(key string) {
	if RedisClient != nil {
		RedisClient.Del(Ctx, key)
	}
}

func InvalidateByPattern(pattern string) {
	if RedisClient == nil {
		return
	}
	// Use pipelining for efficient bulk deletion
	iter := RedisClient.Scan(Ctx, 0, pattern, 0).Iterator()
	pipe := RedisClient.Pipeline()
	count := 0
	for iter.Next(Ctx) {
		pipe.Del(Ctx, iter.Val())
		count++
		if count >= 100 {
			pipe.Exec(Ctx)
			pipe = RedisClient.Pipeline()
			count = 0
		}
	}
	if count > 0 {
		pipe.Exec(Ctx)
	}
}

func InvalidateMovieCache(tmdbID int) {
	InvalidateCache(fmt.Sprintf("movie_%d", tmdbID))
	// Also might be stored by backend ID in some cases, but the requirement specifically asks for tmdb_id pattern
}

func InvalidateSourcesCache(tmdbID int) {
	InvalidateCache(fmt.Sprintf("movie_sources_%d", tmdbID))
	InvalidateByPattern(fmt.Sprintf("tv_sources_%d_*", tmdbID))
}

func InvalidateSearchCache(query string) {
	key := fmt.Sprintf("search_%s", strings.ReplaceAll(strings.ToLower(query), " ", "_"))
	InvalidateCache(key)
}

// Configurable TTLs
var (
	MetadataTTL = 24 * time.Hour
	TrendingTTL = 6 * time.Hour
	SearchTTL   = 1 * time.Hour
	SourcesTTL  = 1 * time.Hour
	ProviderTTL = 30 * time.Minute
)
