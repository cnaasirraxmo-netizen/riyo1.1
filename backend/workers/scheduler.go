package workers

import (
	"log"
	"net/http/httptest"
	"time"

	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/handlers"
	"github.com/riyobox/backend/services"
)

type Scheduler struct {
	MetadataService *services.MetadataService
}

func NewScheduler(ms *services.MetadataService) *Scheduler {
	return &Scheduler{MetadataService: ms}
}

func (s *Scheduler) Start() {
	log.Println("Scheduler started...")

	// Initial sync
	go s.MetadataService.SyncAll()

	// Run every 6 hours
	ticker := time.NewTicker(6 * time.Hour)
	go func() {
		for {
			select {
			case <-ticker.C:
				log.Println("Scheduled task: Syncing Metadata")
				s.MetadataService.SyncAll()
			}
		}
	}()

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
	// Implementation to verify all stored sources and remove dead ones
	// This would typically iterate over movies and check their sources array
	log.Println("Performing Link Health Check...")
}

func (s *Scheduler) WarmupCache() {
	// Simple warming: trigger the handler logic by calling it directly or mimicking request
	// For "home_data"
	cache.InvalidateCache("home_data")

	// We can use httptest to simulate a request to GetHome
	w := httptest.NewRecorder()
	ctx, _ := handlers.CreateTestContext(w) // Assuming we have or add this
	handlers.GetHome(ctx)

	log.Println("Cache warmed: home_data")
}
