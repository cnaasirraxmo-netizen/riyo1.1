package middleware

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ulule/limiter/v3"
	mgin "github.com/ulule/limiter/v3/drivers/middleware/gin"
	"github.com/ulule/limiter/v3/drivers/store/memory"
)

func RateLimit(limit int, period time.Duration) gin.HandlerFunc {
	rate := limiter.Rate{
		Period: period,
		Limit:  int64(limit),
	}
	store := memory.NewStore()
	instance := limiter.New(store, rate)

	return mgin.NewMiddleware(instance, mgin.WithLimitReachedHandler(func(c *gin.Context) {
		c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
			"message": "Too many requests. Please try again later.",
		})
	}))
}

func AuthRateLimit() gin.HandlerFunc {
	return RateLimit(5, time.Minute)
}
