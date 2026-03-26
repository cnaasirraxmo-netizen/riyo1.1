package workers

import (
	"log"
	"net/http/httptest"
	"time"

	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/handlers"
)

type Scheduler struct {
}

func NewScheduler() *Scheduler {
	return &Scheduler{}
}

func (s *Scheduler) Start() {
	log.Println("Scheduler started...")

	// METHOD 8 - BACKGROUND CACHE REFRESH
	// Run every 3 hours
	cacheTicker := time.NewTicker(3 * time.Hour)
	go func() {
		for {
			select {
			case <-cacheTicker.C:
				log.Println("Scheduled task: Warming up cache")
				s.WarmupCache()
			}
		}
	}()

	// Run health check every 6 hours
	healthTicker := time.NewTicker(6 * time.Hour)
	go func() {
		for {
			select {
			case <-healthTicker.C:
				log.Println("Scheduled task: Health check sources")
				s.HealthCheckSources()
			}
		}
	}()
}

func (s *Scheduler) HealthCheckSources() {
	hc := NewHealthChecker()
	hc.CheckAllLinks()
}

func (s *Scheduler) WarmupCache() {
	// Simple warming: trigger the handler logic by calling it directly or mimicking request
	// For "home_data"
	cache.InvalidateCache("home_data")

	// We can use httptest to simulate a request to GetHome
	w := httptest.NewRecorder()
	ctx, _ := handlers.CreateTestContext(w)
	handlers.GetHome(ctx)

	log.Println("Cache warmed: home_data")
}
