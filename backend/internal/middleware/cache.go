package middleware

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/klauspost/compress/zstd"
	"github.com/riyobox/backend/cache"
)

var (
	encoder, _ = zstd.NewWriter(nil)
	decoder, _ = zstd.NewReader(nil)
)

type responseBodyWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (r responseBodyWriter) Write(b []byte) (int, error) {
	r.body.Write(b)
	return r.ResponseWriter.Write(b)
}

func Cache(duration time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		if cache.RedisClient == nil || c.Request.Method != http.MethodGet {
			c.Next()
			return
		}

		// Skip cache for admin and auth routes if needed, but usually GETs are fine
		// unless they contain sensitive info.

		// Generate cache key
		url := c.Request.URL.String()
		hash := sha256.Sum256([]byte(url))
		cacheKey := fmt.Sprintf("http_cache:%s", hex.EncodeToString(hash[:]))

		// Try to get from cache
		val, err := cache.RedisClient.Get(context.Background(), cacheKey).Bytes()
		if err == nil {
			// Decompress if zstd
			var decompressed []byte = val
			if len(val) > 4 && val[0] == 0x28 && val[1] == 0xb5 && val[2] == 0x2f && val[3] == 0xfd {
				decompressed, err = decoder.DecodeAll(val, nil)
				if err == nil {
					c.Header("X-Cache", "HIT")
					c.Data(http.StatusOK, "application/json; charset=utf-8", decompressed)
					c.Abort()
					return
				}
			} else {
				// Not compressed or failed decompression check
				c.Header("X-Cache", "HIT")
				c.Data(http.StatusOK, "application/json; charset=utf-8", val)
				c.Abort()
				return
			}
		}

		// Record response
		w := &responseBodyWriter{body: &bytes.Buffer{}, ResponseWriter: c.Writer}
		c.Writer = w

		c.Next()

		if c.Writer.Status() == http.StatusOK {
			// Compress and cache
			data := w.body.Bytes()
			var finalData []byte = data
			if len(data) > 1024 {
				finalData = encoder.EncodeAll(data, nil)
			}
			cache.RedisClient.Set(context.Background(), cacheKey, finalData, duration)
			c.Header("X-Cache", "MISS")
		}
	}
}
