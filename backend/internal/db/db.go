package db

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

var Client *mongo.Client
var DB *mongo.Database

func ConnectDB() {
	mongoURI := os.Getenv("MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017/riyo"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal(err)
	}

	err = client.Ping(ctx, nil)
	if err != nil {
		log.Printf("⚠️ MongoDB Ping failed, but continuing: %v", err)
	} else {
		fmt.Println("✅ Connected to MongoDB")
	}
	Client = client
	DB = client.Database("riyo")

	SeedDB()
}

func SeedDB() {
	seedCategories()
	seedHomeSections()
	createDefaultAdmin()
}

func seedCategories() {
	collection := DB.Collection("categories")
	count, _ := collection.CountDocuments(context.TODO(), bson.M{})
	if count == 0 {
		fmt.Println("Seeding default categories...")
		categories := []interface{}{
			models.Category{Name: "All", Order: 1, CreatedAt: time.Now(), UpdatedAt: time.Now()},
			models.Category{Name: "Movies", Order: 2, CreatedAt: time.Now(), UpdatedAt: time.Now()},
			models.Category{Name: "TV Shows", Order: 3, CreatedAt: time.Now(), UpdatedAt: time.Now()},
			models.Category{Name: "Anime", Order: 4, CreatedAt: time.Now(), UpdatedAt: time.Now()},
			models.Category{Name: "Kids", Order: 5, CreatedAt: time.Now(), UpdatedAt: time.Now()},
			models.Category{Name: "My List", Order: 6, CreatedAt: time.Now(), UpdatedAt: time.Now()},
		}
		_, err := collection.InsertMany(context.TODO(), categories)
		if err != nil {
			log.Printf("❌ Error seeding categories: %v", err)
		}
	}
}

func seedHomeSections() {
	collection := DB.Collection("homesections")
	count, _ := collection.CountDocuments(context.TODO(), bson.M{})
	if count == 0 {
		fmt.Println("Seeding default home sections...")
		sections := []interface{}{
			models.HomeSection{Title: "Trending Now", Type: "trending", Order: 1, CreatedAt: time.Now(), UpdatedAt: time.Now()},
			models.HomeSection{Title: "Popular on RIYO", Type: "top_rated", Order: 2, CreatedAt: time.Now(), UpdatedAt: time.Now()},
			models.HomeSection{Title: "New Releases", Type: "new_releases", Order: 3, CreatedAt: time.Now(), UpdatedAt: time.Now()},
		}
		_, err := collection.InsertMany(context.TODO(), sections)
		if err != nil {
			log.Printf("❌ Error seeding home sections: %v", err)
		}
	}
}

func createDefaultAdmin() {
	collection := DB.Collection("users")
	adminEmail := "aabahatechnologyada@gmail.com"
	var existingAdmin models.User
	err := collection.FindOne(context.TODO(), bson.M{"email": adminEmail}).Decode(&existingAdmin)

	if err == mongo.ErrNoDocuments {
		fmt.Println("Creating default admin account...")
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("sahan00"), bcrypt.DefaultCost)
		admin := models.User{
			ID:        bson.NewObjectID(),
			Name:      "Sahan",
			Username:  "sahan",
			Email:     adminEmail,
			Password:  string(hashedPassword),
			Role:      "admin",
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		_, err := collection.InsertOne(context.TODO(), admin)
		if err != nil {
			log.Printf("❌ Error creating default admin: %v", err)
		} else {
			fmt.Printf("✅ Default admin created successfully: %s\n", adminEmail)
		}
	} else {
		fmt.Printf("ℹ️ Admin account already exists: %s\n", adminEmail)
	}
}
