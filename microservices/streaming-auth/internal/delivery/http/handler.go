package http

import (
	"encoding/json"
	"net/http"
	"riyo/streaming-auth/internal/usecase"
)

type AuthHandler struct {
	useCase *usecase.StreamingAuthUseCase
}

func NewAuthHandler(uc *usecase.StreamingAuthUseCase) *AuthHandler {
	return &AuthHandler{useCase: uc}
}

func (h *AuthHandler) Authorize(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	contentID := r.URL.Query().Get("content_id")

	if contentID == "" {
		http.Error(w, "content_id is required", http.StatusBadRequest)
		return
	}

	signedURL, err := h.useCase.AuthorizeStream(userID, contentID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusForbidden)
		return
	}

	resp := map[string]interface{}{
		"success": true,
		"data": map[string]string{
			"url": signedURL,
		},
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
