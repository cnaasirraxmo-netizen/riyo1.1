package http

import (
	"encoding/json"
	"net/http"
	"riyo/metadata-service/internal/usecase"
	"strings"
)

type MetadataHandler struct {
	useCase *usecase.MetadataUseCase
}

func NewMetadataHandler(uc *usecase.MetadataUseCase) *MetadataHandler {
	return &MetadataHandler{useCase: uc}
}

func (h *MetadataHandler) GetMovie(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimPrefix(r.URL.Path, "/movies/")
	movie, err := h.useCase.GetMovieDetails(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(movie)
}

func (h *MetadataHandler) ListMovies(w http.ResponseWriter, r *http.Request) {
	genre := r.URL.Query().Get("genre")
	movies, total, err := h.useCase.GetMoviesByCategory(genre, 1, 20)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp := map[string]interface{}{
		"success": true,
		"data": movies,
		"total": total,
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
