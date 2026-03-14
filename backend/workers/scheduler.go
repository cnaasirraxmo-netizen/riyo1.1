package workers

import (
	"log"
	"time"

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
}
