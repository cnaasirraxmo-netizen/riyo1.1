package domain

import "time"

type UserSubscription struct {
	UserID    string    `json:"user_id"`
	Plan      string    `json:"plan"` // free, premium
	IsActive  bool      `json:"is_active"`
	ExpiresAt time.Time `json:"expires_at"`
}

type StreamingAuthUseCase interface {
	AuthorizeStream(userID string, contentID string) (string, error)
	ValidateSubscription(userID string) (*UserSubscription, error)
}
