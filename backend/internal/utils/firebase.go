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

	// 1️⃣ Hubi haddii environment variable uu hayo file path
	if credentialsFile := os.Getenv("FIREBASE_CREDENTIALS_FILE"); credentialsFile != "" {
		log.Println("Initializing Firebase using credentials file path")
		opt := option.WithCredentialsFile(credentialsFile)
		app, err = firebase.NewApp(context.Background(), nil, opt)
	} else if credentialsJSON := os.Getenv("FIREBASE_CREDENTIALS_JSON"); credentialsJSON != "" {
		// 2️⃣ Haddii file path uusan jirin, isku day JSON raw
		log.Println("Initializing Firebase using raw JSON from environment variable")
		opt := option.WithCredentialsJSON([]byte(credentialsJSON))
		app, err = firebase.NewApp(context.Background(), nil, opt)
	} else {
		// 3️⃣ Haddii labaduba maqan yihiin, isku day default credentials
		log.Println("Initializing Firebase using default credentials")
		app, err = firebase.NewApp(context.Background(), nil)
	}

	if err != nil {
		log.Fatalf("error initializing firebase app: %v", err)
	}

	client, err := app.Auth(context.Background())
	if err != nil {
		log.Fatalf("error getting firebase auth client: %v", err)
	}

	FirebaseApp = app
	FirebaseAuth = client
	log.Println("Firebase initialized successfully")
}

// VerifyFirebaseToken verifies the Firebase ID token
func VerifyFirebaseToken(idToken string) (*auth.Token, error) {
	if FirebaseAuth == nil {
		return nil, nil // ama ka handle error sidaad rabto
	}
	return FirebaseAuth.VerifyIDToken(context.Background(), idToken)
}
