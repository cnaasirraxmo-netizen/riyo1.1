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
	var app *firebase.App
	var err error

	// Akhri JSON credentials ka env variable
	jsonCreds := os.Getenv("FIREBASE_CREDENTIALS_FILE")
	if jsonCreds != "" {
		opt := option.WithCredentialsJSON([]byte(jsonCreds)) // ✅ Isticmaal JSON content
		app, err = firebase.NewApp(context.Background(), nil, opt)
		log.Println("Initializing Firebase using credentials JSON from environment")
	} else {
		// Fallback to default credentials (ADC) ama local file
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
		return nil, nil // ama error gaar ah
	}
	return FirebaseAuth.VerifyIDToken(context.Background(), idToken)
}
