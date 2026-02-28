package usecase

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"riyo/streaming-auth/internal/domain"
	"time"
)

type StreamingAuthUseCase struct {
	secretKey string
}

func NewStreamingAuthUseCase(secret string) *StreamingAuthUseCase {
	return &StreamingAuthUseCase{secretKey: secret}
}

func (u *StreamingAuthUseCase) AuthorizeStream(userID string, contentID string) (string, error) {
	// 1. In a real app, check subscription status via User Service or DB
	// For now, assume authorized

	// 2. Generate a signed URL for the CDN (Cloudflare/CloudFront)
	// Example: /videos/processed/movie-1/master.m3u8?token=...
	expires := time.Now().Add(1 * time.Hour).Unix()
	rawPath := fmt.Sprintf("/videos/processed/%s/master.m3u8", contentID)

	token := u.generateToken(rawPath, expires)
	signedURL := fmt.Sprintf("%s?expires=%d&token=%s", rawPath, expires, token)

	return signedURL, nil
}

func (u *StreamingAuthUseCase) generateToken(path string, expires int64) string {
	mac := hmac.New(sha256.New, []byte(u.secretKey))
	data := fmt.Sprintf("%s:%d", path, expires)
	mac.Write([]byte(data))
	return hex.EncodeToString(mac.Sum(nil))
}

func (u *StreamingAuthUseCase) ValidateSubscription(userID string) (*domain.UserSubscription, error) {
	return &domain.UserSubscription{
		UserID:   userID,
		Plan:     "premium",
		IsActive: true,
	}, nil
}
