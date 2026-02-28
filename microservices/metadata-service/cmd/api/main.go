package main

import (
	"log"
	"net/http"
	"riyo/metadata-service/internal/repository"
	"riyo/metadata-service/internal/usecase"
	delivery "riyo/metadata-service/internal/delivery/http"
	"riyo/metadata-service/internal/domain"
)

func main() {
	repo := repository.NewInMemoryMovieRepository()
	// Seed initial data
	repo.Seed([]*domain.Movie{
		{
			ID: "movie-1",
			Title: "Inception",
			Description: "A thief who steals corporate secrets through the use of dream-sharing technology.",
			PosterURL: "https://example.com/inception.jpg",
			VideoURL: "/videos/processed/movie-1/master.m3u8",
			Genre: "Sci-Fi",
			Year: 2010,
			IsFeatured: true,
		},
		{
			ID: "movie-2",
			Title: "The Dark Knight",
			Description: "Batman fights the Joker.",
			PosterURL: "https://example.com/darkknight.jpg",
			VideoURL: "/videos/processed/movie-2/master.m3u8",
			Genre: "Action",
			Year: 2008,
			IsFeatured: true,
		},
	})

	metadataUC := usecase.NewMetadataUseCase(repo)
	handler := delivery.NewMetadataHandler(metadataUC)

	mux := http.NewServeMux()
	mux.HandleFunc("/movies/", handler.GetMovie)
	mux.HandleFunc("/movies", handler.ListMovies)

	log.Println("Metadata Service listening on :5002")
	if err := http.ListenAndServe(":5002", mux); err != nil {
		log.Fatal(err)
	}
}
