package domain

import "time"

type JobStatus string

const (
	StatusPending    JobStatus = "PENDING"
	StatusProcessing JobStatus = "PROCESSING"
	StatusCompleted  JobStatus = "COMPLETED"
	StatusFailed     JobStatus = "FAILED"
)

type ProcessingJob struct {
	ID           string    `json:"id"`
	SourceURL    string    `json:"source_url"`
	TargetFolder string    `json:"target_folder"`
	Status       JobStatus `json:"status"`
	Progress     float64   `json:"progress"`
	Resolutions  []string  `json:"resolutions"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type JobRepository interface {
	Create(job *ProcessingJob) error
	Update(job *ProcessingJob) error
	GetByID(id string) (*ProcessingJob, error)
	ListPending() ([]*ProcessingJob, error)
}
