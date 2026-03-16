package utils

import (
	"context"
	"errors"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

var FirebaseApp *firebase.App
var FirebaseAuth *auth.Client

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

	client, err := app.Auth(context.Background())
	if err != nil {
		log.Fatalf("Error getting Firebase auth client: %v", err)
		return
	}

	FirebaseApp = app
	FirebaseAuth = client
	log.Println("Firebase initialized successfully")
}

func VerifyFirebaseToken(idToken string) (*auth.Token, error) {
	if FirebaseAuth == nil {
		return nil, errors.New("firebase auth client not initialized")
	}
	return FirebaseAuth.VerifyIDToken(context.Background(), idToken)
}
