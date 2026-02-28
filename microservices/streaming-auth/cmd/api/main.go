package main

import (
	"log"
	"net/http"
	"riyo/streaming-auth/internal/usecase"
	delivery "riyo/streaming-auth/internal/delivery/http"
)

func main() {
	// Secret key should be loaded from ENV
	authUC := usecase.NewStreamingAuthUseCase("super-secret-key")
	handler := delivery.NewAuthHandler(authUC)

	mux := http.NewServeMux()
	mux.HandleFunc("/authorize", handler.Authorize)

	log.Println("Streaming Authorization Service listening on :5003")
	if err := http.ListenAndServe(":5003", mux); err != nil {
		log.Fatal(err)
	}
}
