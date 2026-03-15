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
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = os.Getenv("REDIS_PUBLIC_URL")
	}

	var opts *redis.Options
	var err error

	if redisURL != "" {
		opts, err = redis.ParseURL(redisURL)
		if err != nil {
			log.Printf("Failed to parse Redis URL: %v", err)
		}
	}

	if opts == nil {
		host := os.Getenv("REDISHOST")
		port := os.Getenv("REDISPORT")
		user := os.Getenv("REDISUSER")
		pass := os.Getenv("REDISPASSWORD")

		if host != "" && port != "" {
			opts = &redis.Options{
				Addr:     fmt.Sprintf("%s:%s", host, port),
				Username: user,
				Password: pass,
			}
		}
	}

	if opts == nil {
		log.Println("Redis environment variables not set, caching disabled")
		return
	}

	// Connection pooling and optimization
	opts.PoolSize = 100
	opts.MinIdleConns = 10
	opts.DialTimeout = 5 * time.Second
	opts.ReadTimeout = 3 * time.Second
	opts.WriteTimeout = 3 * time.Second

	if dbStr := os.Getenv("REDIS_DB"); dbStr != "" {
		if db, err := strconv.Atoi(dbStr); err == nil {
			opts.DB = db
		}
	}

	RedisClient = redis.NewClient(opts)

	// Automatic reconnect is handled by go-redis, but we'll do a Ping to verify
	_, err = RedisClient.Ping(Ctx).Result()
	if err != nil {
		log.Printf("Warning: Redis connection failed: %v. System will fallback to database/scrapers.", err)
		RedisClient = nil
	} else {
		log.Println("Connected to Redis successfully")
	}
}

func GetOrSetCache(key string, ttl time.Duration, fetchFunc func() (interface{}, error)) (interface{}, error) {
	if RedisClient == nil {
		return fetchFunc()
	}

	start := time.Now()

	// 1. Check Redis for the key
	val, err := RedisClient.Get(Ctx, key).Bytes()
	if err == nil {
		// Decompress
		decompressed, err := decoder.DecodeAll(val, nil)
		if err == nil {
			var data interface{}
			if err := json.Unmarshal(decompressed, &data); err == nil {
				// Cache Hit
				latency := time.Since(start)
				log.Printf("[CACHE HIT] Key: %s | Latency: %v", key, latency)
				return data, nil
			}
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

		// Compress
		compressed := encoder.EncodeAll(data, nil)

		err = RedisClient.Set(Ctx, key, compressed, ttl).Err()
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
	MetadataTTL      = 24 * time.Hour
	TrendingTTL      = 6 * time.Hour
	SearchTTL        = 1 * time.Hour
	SourcesTTL       = 1 * time.Hour
	ProviderTTL      = 30 * time.Minute
)
