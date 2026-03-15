package utils

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

var FirebaseApp *firebase.App
var FirebaseAuth *auth.Client

func InitFirebase() {
	// Attempt to initialize from credentials file if it exists, otherwise use default
	var app *firebase.App
	var err error

	credentialsFile := os.Getenv("FIREBASE_CREDENTIALS_FILE")
	if credentialsFile != "" {
		opt := option.WithCredentialsFile(credentialsFile)
		app, err = firebase.NewApp(context.Background(), nil, opt)
	} else {
		// Fallback to environment variables or local ADC
		app, err = firebase.NewApp(context.Background(), nil)
	}

	if err != nil {
		log.Printf("error initializing firebase app: %v", err)
		return
	}

	client, err := app.Auth(context.Background())
	if err != nil {
		log.Printf("error getting firebase auth client: %v", err)
		return
	}

	FirebaseApp = app
	FirebaseAuth = client
	log.Println("Firebase initialized successfully")
}

func VerifyFirebaseToken(idToken string) (*auth.Token, error) {
	if FirebaseAuth == nil {
		return nil, nil // Or handle error
	}
	return FirebaseAuth.VerifyIDToken(context.Background(), idToken)
}
