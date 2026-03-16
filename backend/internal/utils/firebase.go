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
	// Akhri path ka JSON file-ka laga keenay env variable
	credentialsFile := os.Getenv("FIREBASE_CREDENTIALS_FILE")
	if credentialsFile == "" {
		log.Println("FIREBASE_CREDENTIALS_FILE environment variable not set")
		return
	}

	// Isticmaal file path si aad u abuurto Firebase app
	opt := option.WithCredentialsFile(credentialsFile)
	app, err := firebase.NewApp(context.Background(), nil, opt)
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
		return nil, nil // ama handle error sida aad rabto
	}
	return FirebaseAuth.VerifyIDToken(context.Background(), idToken)
}
