package utils

import (
	"context"
	"errors"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var FirebaseApp *firebase.App
var FirebaseAuth *auth.Client
var FirebaseMessaging *messaging.Client

func InitFirebase() {
	var app *firebase.App
	var err error

	// Load Firebase credentials from JSON file
	jsonCreds := os.Getenv("FIREBASE_CREDENTIALS_FILE")
	if jsonCreds != "" {
		opt := option.WithCredentialsFile(jsonCreds)
		app, err = firebase.NewApp(context.Background(), nil, opt)
		log.Printf("Initializing Firebase using credentials file: %s\n", jsonCreds)
	} else {
		// Fallback to default credentials (ADC)
		app, err = firebase.NewApp(context.Background(), nil)
		log.Println("Initializing Firebase using default credentials")
	}

	if err != nil {
		log.Fatalf("Error initializing Firebase app: %v", err)
		return
	}

	authClient, err := app.Auth(context.Background())
	if err != nil {
		log.Fatalf("Error getting Firebase auth client: %v", err)
		return
	}

	msgClient, err := app.Messaging(context.Background())
	if err != nil {
		log.Printf("Error getting Firebase messaging client: %v", err)
		// We don't necessarily want to fatal here if only messaging fails
	}

	FirebaseApp = app
	FirebaseAuth = authClient
	FirebaseMessaging = msgClient
	log.Println("Firebase initialized successfully")
}

func LogErrorf(format string, v ...interface{}) {
	log.Printf("ERROR: "+format, v...)
}

func VerifyFirebaseToken(idToken string) (*auth.Token, error) {
	if FirebaseAuth == nil {
		return nil, errors.New("firebase auth client not initialized")
	}
	return FirebaseAuth.VerifyIDToken(context.Background(), idToken)
}

func SendPushNotification(ctx context.Context, tokens []string, title, body string, data map[string]string) error {
	if FirebaseMessaging == nil {
		return errors.New("firebase messaging client not initialized")
	}

	if len(tokens) == 0 {
		return nil
	}

	// FCM allows up to 500 tokens per multicast message
	const batchSize = 500
	var finalErr error

	for i := 0; i < len(tokens); i += batchSize {
		end := i + batchSize
		if end > len(tokens) {
			end = len(tokens)
		}

		batch := tokens[i:end]

		if len(batch) == 1 {
			message := &messaging.Message{
				Token: batch[0],
				Notification: &messaging.Notification{
					Title: title,
					Body:  body,
				},
				Data: data,
			}
			_, err := FirebaseMessaging.Send(ctx, message)
			if err != nil {
				finalErr = err
			}
			continue
		}

		message := &messaging.MulticastMessage{
			Tokens: batch,
			Notification: &messaging.Notification{
				Title: title,
				Body:  body,
			},
			Data: data,
		}

		response, err := FirebaseMessaging.SendEachForMulticast(ctx, message)
		if err != nil {
			finalErr = err
			continue
		}

		// Cleanup invalid tokens if needed
		if response.FailureCount > 0 {
			go handleBatchFailures(batch, response.Responses)
		}
	}

	return finalErr
}

func handleBatchFailures(tokens []string, responses []*messaging.SendResponse) {
	// This is a placeholder for token cleanup logic.
	// In a real app, you'd want to remove invalid tokens from the DB.
	for i, resp := range responses {
		if !resp.Success {
			// Check if error is "registration-token-not-registered" or "invalid-argument"
			// and remove from DB
			log.Printf("Failed to send to token %s: %v", tokens[i], resp.Error)
		}
	}
}

func SendToTopic(ctx context.Context, topic, title, body string, data map[string]string) error {
	if FirebaseMessaging == nil {
		return errors.New("firebase messaging client not initialized")
	}

	message := &messaging.Message{
		Topic: topic,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
	}
	_, err := FirebaseMessaging.Send(ctx, message)
	return err
}

func SubscribeToTopic(ctx context.Context, tokens []string, topic string) error {
	if FirebaseMessaging == nil {
		return errors.New("firebase messaging client not initialized")
	}
	_, err := FirebaseMessaging.SubscribeToTopic(ctx, tokens, topic)
	return err
}

func UnsubscribeFromTopic(ctx context.Context, tokens []string, topic string) error {
	if FirebaseMessaging == nil {
		return errors.New("firebase messaging client not initialized")
	}
	_, err := FirebaseMessaging.UnsubscribeFromTopic(ctx, tokens, topic)
	return err
}
