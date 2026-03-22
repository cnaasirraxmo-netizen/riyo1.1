package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/riyobox/backend/internal/db"
	"go.mongodb.org/mongo-driver/v2/bson"
)

func main() {
	godotenv.Load()

	db.ConnectDB()
	collection := db.DB.Collection("movies")

	// Update movies that don't have a sourceType
	filter := bson.M{"sourceType": bson.M{"$exists": false}}
	update := bson.M{
		"$set": bson.M{
			"sourceType": "scraped",
			"isScraped":  true,
		},
	}

	result, err := collection.UpdateMany(context.TODO(), filter, update)
	if err != nil {
		log.Fatalf("Migration failed: %v", err)
	}

	fmt.Printf("Updated %d movies to 'scraped' type\n", result.ModifiedCount)

	// Specifically handle movies that have a local videoUrl or were created by admin
	// For this system, we can assume if tmdbId is 0 or it has a local-looking URL, it might be admin content
	// But the safest is to just mark everything old as scraped and let admin re-save if needed,
	// OR mark movies with VideoURL but no sourceType as admin if VideoURL contains R2/S3 patterns.

	adminFilter := bson.M{
		"$or": []bson.M{
			{"videoUrl": bson.M{"$regex": "r2.dev"}},
			{"videoUrl": bson.M{"$regex": "amazonaws"}},
		},
		"sourceType": "scraped", // Only those we just marked
	}

	adminUpdate := bson.M{
		"$set": bson.M{
			"sourceType": "admin",
			"isScraped":  false,
		},
	}

	result, err = collection.UpdateMany(context.TODO(), adminFilter, adminUpdate)
	if err != nil {
		log.Printf("Admin migration warning: %v", err)
	} else {
		fmt.Printf("Updated %d potential admin movies to 'admin' type\n", result.ModifiedCount)
	}
}
