package usecase

import (
	"riyo/metadata-service/internal/domain"
)

type MetadataUseCase struct {
	movieRepo domain.MovieRepository
}

func NewMetadataUseCase(repo domain.MovieRepository) *MetadataUseCase {
	return &MetadataUseCase{movieRepo: repo}
}

func (u *MetadataUseCase) GetMovieDetails(id string) (*domain.Movie, error) {
	return u.movieRepo.GetByID(id)
}

func (u *MetadataUseCase) GetFeaturedContent() ([]*domain.Movie, error) {
	return u.movieRepo.ListFeatured()
}

func (u *MetadataUseCase) GetMoviesByCategory(category string, page, limit int) ([]*domain.Movie, int, error) {
	return u.movieRepo.ListByCategory(category, page, limit)
}
