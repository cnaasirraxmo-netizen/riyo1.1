package usecase

import (
	"fmt"
	"log"
	"riyo/video-processing/internal/domain"
	"riyo/video-processing/pkg/ffmpeg"
	"time"
)

type VideoUseCase struct {
	repo       domain.JobRepository
	transcoder *ffmpeg.Transcoder
}

func NewVideoUseCase(repo domain.JobRepository) *VideoUseCase {
	return &VideoUseCase{
		repo:       repo,
		transcoder: ffmpeg.NewTranscoder(),
	}
}

func (v *VideoUseCase) ProcessJob(jobID string) error {
	job, err := v.repo.GetByID(jobID)
	if err != nil {
		return err
	}

	job.Status = domain.StatusProcessing
	job.UpdatedAt = time.Now()
	v.repo.Update(job)

	log.Printf("Starting job %s for %s", jobID, job.SourceURL)

	for _, res := range job.Resolutions {
		outputPath := fmt.Sprintf("%s/%s", job.TargetFolder, res)
		err := v.transcoder.GenerateHLS(job.SourceURL, outputPath, res)
		if err != nil {
			job.Status = domain.StatusFailed
			v.repo.Update(job)
			return err
		}
	}

	err = v.transcoder.GenerateMasterPlaylist(job.TargetFolder, job.Resolutions)
	if err != nil {
		job.Status = domain.StatusFailed
		v.repo.Update(job)
		return err
	}

	job.Status = domain.StatusCompleted
	job.UpdatedAt = time.Now()
	v.repo.Update(job)

	log.Printf("Successfully completed job %s", jobID)
	return nil
}
