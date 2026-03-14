package services

import (
	"context"
	"log"
	"strconv"
	"time"

	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type MetadataService struct {
	TMDB *providers.TMDbProvider
}

func NewMetadataService(tmdb *providers.TMDbProvider) *MetadataService {
	return &MetadataService{TMDB: tmdb}
}

func (s *MetadataService) SyncTrendingMovies() error {
	tmdbMovies, err := s.TMDB.FetchTrendingMovies()
	if err != nil {
		return err
	}

	for _, tm := range tmdbMovies {
		s.saveMovie(tm, true, false)
	}
	return nil
}

func (s *MetadataService) SyncPopularMovies() error {
	tmdbMovies, err := s.TMDB.FetchPopularMovies()
	if err != nil {
		return err
	}

	for _, tm := range tmdbMovies {
		s.saveMovie(tm, false, false)
	}
	return nil
}

func (s *MetadataService) SyncTrendingTVShows() error {
	tmdbTVShows, err := s.TMDB.FetchTrendingTVShows()
	if err != nil {
		return err
	}

	for _, tt := range tmdbTVShows {
		s.saveTVShow(tt, true, false)
	}
	return nil
}

func (s *MetadataService) saveMovie(tm providers.TMDbMovie, isTrending bool, isFeatured bool) {
	collection := db.DB.Collection("movies")

	var existing models.Movie
	err := collection.FindOne(context.TODO(), bson.M{"tmdbId": tm.ID}).Decode(&existing)

	posterURL := "https://image.tmdb.org/t/p/w500" + tm.PosterPath
	bannerURL := "https://image.tmdb.org/t/p/original" + tm.BackdropPath

	year := 0
	if len(tm.ReleaseDate) >= 4 {
		year, _ = strconv.Atoi(tm.ReleaseDate[:4])
	}

	if err == mongo.ErrNoDocuments {
		movie := models.Movie{
			ID:           bson.NewObjectID(),
			TMDbID:       tm.ID,
			Title:        tm.Title,
			Description:  tm.Overview,
			PosterURL:    posterURL,
			BannerURL:    bannerURL,
			Rating:       tm.VoteAverage,
			Year:         year,
			IsTrending:   isTrending,
			IsFeatured:   isFeatured,
			IsTvShow:     false,
			Status:       "published",
			AccessType:   "free",
			CreatedAt:    time.Now(),
			UpdatedAt:    time.Now(),
		}
		_, _ = collection.InsertOne(context.TODO(), movie)
	} else {
		update := bson.M{
			"$set": bson.M{
				"title":       tm.Title,
				"description": tm.Overview,
				"posterUrl":   posterURL,
				"bannerUrl":   bannerURL,
				"rating":      tm.VoteAverage,
				"year":        year,
				"isTrending":  isTrending || existing.IsTrending,
				"updatedAt":   time.Now(),
			},
		}
		_, _ = collection.UpdateOne(context.TODO(), bson.M{"tmdbId": tm.ID}, update)
	}
}

func (s *MetadataService) saveTVShow(tt providers.TMDbTVShow, isTrending bool, isFeatured bool) {
	collection := db.DB.Collection("movies")

	var existing models.Movie
	err := collection.FindOne(context.TODO(), bson.M{"tmdbId": tt.ID}).Decode(&existing)

	posterURL := "https://image.tmdb.org/t/p/w500" + tt.PosterPath
	bannerURL := "https://image.tmdb.org/t/p/original" + tt.BackdropPath

	year := 0
	if len(tt.FirstAirDate) >= 4 {
		year, _ = strconv.Atoi(tt.FirstAirDate[:4])
	}

	if err == mongo.ErrNoDocuments {
		tvShow := models.Movie{
			ID:           bson.NewObjectID(),
			TMDbID:       tt.ID,
			Title:        tt.Name,
			Description:  tt.Overview,
			PosterURL:    posterURL,
			BannerURL:    bannerURL,
			Rating:       tt.VoteAverage,
			Year:         year,
			IsTrending:   isTrending,
			IsFeatured:   isFeatured,
			IsTvShow:     true,
			Status:       "published",
			AccessType:   "free",
			CreatedAt:    time.Now(),
			UpdatedAt:    time.Now(),
		}
		_, _ = collection.InsertOne(context.TODO(), tvShow)
	} else {
		update := bson.M{
			"$set": bson.M{
				"title":       tt.Name,
				"description": tt.Overview,
				"posterUrl":   posterURL,
				"bannerUrl":   bannerURL,
				"rating":      tt.VoteAverage,
				"year":        year,
				"isTrending":  isTrending || existing.IsTrending,
				"updatedAt":   time.Now(),
			},
		}
		_, _ = collection.UpdateOne(context.TODO(), bson.M{"tmdbId": tt.ID}, update)
	}
}

func (s *MetadataService) SyncAll() {
	log.Println("Starting Metadata Sync...")
	if err := s.SyncTrendingMovies(); err != nil {
		log.Printf("Error syncing trending movies: %v", err)
	}
	if err := s.SyncPopularMovies(); err != nil {
		log.Printf("Error syncing popular movies: %v", err)
	}
	if err := s.SyncTrendingTVShows(); err != nil {
		log.Printf("Error syncing trending TV shows: %v", err)
	}
	log.Println("Metadata Sync Completed.")
}
