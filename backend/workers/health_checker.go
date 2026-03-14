package workers

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
)

type HealthChecker struct{}

func NewHealthChecker() *HealthChecker {
	return &HealthChecker{}
}

func (h *HealthChecker) Start() {
	log.Println("Health Checker started...")
	ticker := time.NewTicker(12 * time.Hour)
	go func() {
		for {
			select {
			case <-ticker.C:
				h.CheckAllLinks()
			}
		}
	}()
}

func (h *HealthChecker) CheckAllLinks() {
	log.Println("Checking link health...")
	collection := db.DB.Collection("movies")
	cursor, err := collection.Find(context.TODO(), bson.M{})
	if err != nil {
		return
	}
	defer cursor.Close(context.TODO())

	for cursor.Next(context.TODO()) {
		var movie models.Movie
		if err := cursor.Decode(&movie); err != nil {
			continue
		}

		updatedSources := []models.StreamSource{}
		changed := false

		for _, source := range movie.Sources {
			if source.Type == "embed" {
				// We don't easily health check embeds without a browser
				updatedSources = append(updatedSources, source)
				continue
			}

			if h.ValidateLink(source.URL) {
				updatedSources = append(updatedSources, source)
			} else {
				log.Printf("Removing broken link: %s for %s", source.URL, movie.Title)
				changed = true
			}
		}

		if changed {
			collection.UpdateOne(context.TODO(), bson.M{"_id": movie.ID}, bson.M{"$set": bson.M{"sources": updatedSources}})
		}
	}
}

func (h *HealthChecker) ValidateLink(url string) bool {
	client := http.Client{
		Timeout: 5 * time.Second,
	}
	resp, err := client.Head(url)
	if err != nil {
		return false
	}
	return resp.StatusCode == http.StatusOK
}
