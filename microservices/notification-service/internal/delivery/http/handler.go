package http

import (
	"encoding/json"
	"net/http"
	"riyo/notification-service/internal/usecase"
)

type NotificationHandler struct {
	useCase *usecase.NotificationUseCase
}

func NewNotificationHandler(uc *usecase.NotificationUseCase) *NotificationHandler {
	return &NotificationHandler{useCase: uc}
}

func (h *NotificationHandler) SendNotification(w http.ResponseWriter, r *http.Request) {
	var body struct {
		UserID  string `json:"user_id"`
		Title   string `json:"title"`
		Message string `json:"message"`
	}

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if body.UserID == "" {
		h.useCase.SendGlobal(body.Title, body.Message)
	} else {
		h.useCase.SendPush(body.UserID, body.Title, body.Message)
	}

	resp := map[string]interface{}{"success": true, "message": "Notification queued"}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
