package main

import (
	"log"
	"net/http"
	"riyo/notification-service/internal/usecase"
	delivery "riyo/notification-service/internal/delivery/http"
)

func main() {
	notificationUC := usecase.NewNotificationUseCase()
	handler := delivery.NewNotificationHandler(notificationUC)

	mux := http.NewServeMux()
	mux.HandleFunc("/send", handler.SendNotification)

	log.Println("Notification Service listening on :5004")
	if err := http.ListenAndServe(":5004", mux); err != nil {
		log.Fatal(err)
	}
}
