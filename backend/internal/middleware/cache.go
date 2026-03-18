package middleware

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/cache"
)

type responseBodyWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (r *responseBodyWriter) Write(b []byte) (int, error) {
	r.body.Write(b)
	return r.ResponseWriter.Write(b)
}

func Cache(ttl time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		if cache.RedisClient == nil || c.Request.Method != http.MethodGet {
			c.Next()
			return
		}

		// Generate a unique cache key based on URL and query params
		hash := md5.Sum([]byte(c.Request.URL.RequestURI()))
		key := fmt.Sprintf("http_cache:%s", hex.EncodeToString(hash[:]))

		// Try to get from cache
		val, err := cache.RedisClient.Get(cache.Ctx, key).Bytes()
		if err == nil {
			var data interface{}
			if err := json.Unmarshal(val, &data); err == nil {
				c.Header("X-Cache", "HIT")
				c.JSON(http.StatusOK, data)
				c.Abort()
				return
			}
		}

		// Cache Miss - Capture the response
		w := &responseBodyWriter{body: &bytes.Buffer{}, ResponseWriter: c.Writer}
		c.Writer = w

		c.Header("X-Cache", "MISS")
		c.Next()

		// If the response was successful, store it in cache
		if c.Writer.Status() == http.StatusOK {
			go func(k string, b []byte, t time.Duration) {
				var responseData interface{}
				if err := json.Unmarshal(b, &responseData); err == nil {
					// We verify it's valid JSON before caching
					cache.RedisClient.Set(cache.Ctx, k, b, t)
				}
			}(key, w.body.Bytes(), ttl)
		}
	}
}
