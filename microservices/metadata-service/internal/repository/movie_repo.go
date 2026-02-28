package repository

import (
	"errors"
	"riyo/metadata-service/internal/domain"
	"sync"
)

type InMemoryMovieRepository struct {
	mu     sync.RWMutex
	movies map[string]*domain.Movie
}

func NewInMemoryMovieRepository() *InMemoryMovieRepository {
	return &InMemoryMovieRepository{
		movies: make(map[string]*domain.Movie),
	}
}

func (r *InMemoryMovieRepository) GetByID(id string) (*domain.Movie, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	movie, exists := r.movies[id]
	if !exists {
		return nil, errors.New("movie not found")
	}
	return movie, nil
}

func (r *InMemoryMovieRepository) ListFeatured() ([]*domain.Movie, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var featured []*domain.Movie
	for _, m := range r.movies {
		if m.IsFeatured {
			featured = append(featured, m)
		}
	}
	return featured, nil
}

func (r *InMemoryMovieRepository) ListByCategory(category string, page, limit int) ([]*domain.Movie, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var filtered []*domain.Movie
	for _, m := range r.movies {
		if m.Genre == category || category == "" {
			filtered = append(filtered, m)
		}
	}
	return filtered, len(filtered), nil
}

func (r *InMemoryMovieRepository) Seed(movies []*domain.Movie) {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, m := range movies {
		r.movies[m.ID] = m
	}
}
