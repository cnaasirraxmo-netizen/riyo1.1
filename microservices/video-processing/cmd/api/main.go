package main

import (
	"log"
	"riyo/video-processing/internal/repository"
	"riyo/video-processing/internal/usecase"
	"riyo/video-processing/internal/domain"
	"time"
)

func main() {
	repo := repository.NewInMemoryJobRepository()
	videoUC := usecase.NewVideoUseCase(repo)

	// Mocking a Kafka listener or Job Queue consumer
	log.Println("Video Processing Service started...")

	// Create a test job
	testJob := &domain.ProcessingJob{
		ID:           "test-1",
		SourceURL:    "uploads/raw/test.mp4",
		TargetFolder: "videos/processed/test-1",
		Status:       domain.StatusPending,
		Resolutions:  []string{"720p", "480p"},
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	repo.Create(testJob)

	// In a real implementation, this would be triggered by a Kafka message
	err := videoUC.ProcessJob(testJob.ID)
	if err != nil {
		log.Printf("Job failed: %v", err)
	}

	// Keep the service alive
	select {}
}
