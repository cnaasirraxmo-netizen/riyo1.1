package repository

import (
	"errors"
	"riyo/video-processing/internal/domain"
	"sync"
)

type InMemoryJobRepository struct {
	mu   sync.RWMutex
	jobs map[string]*domain.ProcessingJob
}

func NewInMemoryJobRepository() *InMemoryJobRepository {
	return &InMemoryJobRepository{
		jobs: make(map[string]*domain.ProcessingJob),
	}
}

func (r *InMemoryJobRepository) Create(job *domain.ProcessingJob) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, exists := r.jobs[job.ID]; exists {
		return errors.New("job already exists")
	}
	r.jobs[job.ID] = job
	return nil
}

func (r *InMemoryJobRepository) Update(job *domain.ProcessingJob) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, exists := r.jobs[job.ID]; !exists {
		return errors.New("job not found")
	}
	r.jobs[job.ID] = job
	return nil
}

func (r *InMemoryJobRepository) GetByID(id string) (*domain.ProcessingJob, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	job, exists := r.jobs[id]
	if !exists {
		return nil, errors.New("job not found")
	}
	return job, nil
}

func (r *InMemoryJobRepository) ListPending() ([]*domain.ProcessingJob, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var pending []*domain.ProcessingJob
	for _, job := range r.jobs {
		if job.Status == domain.StatusPending {
			pending = append(pending, job)
		}
	}
	return pending, nil
}
