package usecase

import (
	"log"
)

type NotificationUseCase struct {
}

func NewNotificationUseCase() *NotificationUseCase {
	return &NotificationUseCase{}
}

func (u *NotificationUseCase) SendPush(userID string, title, message string) error {
	// In a real app, use Firebase Cloud Messaging (FCM)
	log.Printf("[FCM] Sending push to User %s: %s - %s", userID, title, message)
	return nil
}

func (u *NotificationUseCase) SendGlobal(title, message string) error {
	log.Printf("[FCM] Sending global notification: %s - %s", title, message)
	return nil
}
