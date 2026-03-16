package services

import (
	"context"
	"log"
	"strconv"
	"time"

	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/providers"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type MetadataService struct {
	TMDB *providers.TMDbProvider
	Genres map[int]string
}

func NewMetadataService(tmdb *providers.TMDbProvider) *MetadataService {
	genres, _ := tmdb.FetchGenres()
	return &MetadataService{TMDB: tmdb, Genres: genres}
}

func (s *MetadataService) SyncTrendingMovies() error {
	tmdbMovies, err := s.TMDB.FetchTrendingMovies()
	if err != nil {
		return err
	}

	for _, tm := range tmdbMovies {
		s.SyncMovieFull(tm.ID, true, false)
	}
	return nil
}

func (s *MetadataService) SyncPopularMovies() error {
	tmdbMovies, err := s.TMDB.FetchPopularMovies()
	if err != nil {
		return err
	}

	for _, tm := range tmdbMovies {
		s.SyncMovieFull(tm.ID, false, false)
	}
	return nil
}

func (s *MetadataService) SyncTrendingTVShows() error {
	tmdbTVShows, err := s.TMDB.FetchTrendingTVShows()
	if err != nil {
		return err
	}

	for _, tt := range tmdbTVShows {
		s.SyncTVShowFull(tt.ID, true, false)
	}
	return nil
}

func (s *MetadataService) getGenreNames(ids []int) []string {
	names := []string{}
	for _, id := range ids {
		if name, ok := s.Genres[id]; ok {
			names = append(names, name)
		}
	}
	return names
}

func (s *MetadataService) SyncMovieFull(tmdbID int, isTrending bool, isFeatured bool) {
	tm, err := s.TMDB.FetchMovieDetails(tmdbID)
	if err != nil {
		log.Printf("Error fetching movie details for %d: %v", tmdbID, err)
		return
	}

	collection := db.DB.Collection("movies")

	var existing models.Movie
	err = collection.FindOne(context.TODO(), bson.M{"tmdbId": tmdbID}).Decode(&existing)

	posterURL := "https://image.tmdb.org/t/p/w500" + tm.PosterPath
	bannerURL := "https://image.tmdb.org/t/p/original" + tm.BackdropPath

	year := 0
	if len(tm.ReleaseDate) >= 4 {
		year, _ = strconv.Atoi(tm.ReleaseDate[:4])
	}

	genres := s.getGenreNames(tm.GenreIDs)
	cast := []string{}
	if tm.Credits != nil {
		for i, c := range tm.Credits.Cast {
			if i >= 10 { break }
			cast = append(cast, c.Name)
		}
	}

	if err == mongo.ErrNoDocuments {
		movie := models.Movie{
			ID:           bson.NewObjectID(),
			TMDbID:       tmdbID,
			Title:        tm.Title,
			Description:  tm.Overview,
			PosterURL:    posterURL,
			BannerURL:    bannerURL,
			Rating:       tm.VoteAverage,
			Year:         year,
			Genre:        genres,
			Cast:         cast,
			Duration:     tm.Runtime,
			IsTrending:   isTrending,
			IsFeatured:   isFeatured,
			IsTvShow:     false,
			IsPublished:  true,
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
				"genre":       genres,
				"cast":        cast,
				"duration":    tm.Runtime,
				"isTrending":  isTrending || existing.IsTrending,
				"updatedAt":   time.Now(),
			},
		}
		_, _ = collection.UpdateOne(context.TODO(), bson.M{"tmdbId": tmdbID}, update)
	}
	cache.InvalidateMovieCache(tmdbID)
	cache.InvalidateCache("home_data")
}

func (s *MetadataService) SyncTVShowFull(tmdbID int, isTrending bool, isFeatured bool) {
	tt, err := s.TMDB.FetchTVShowDetails(tmdbID)
	if err != nil {
		log.Printf("Error fetching TV details for %d: %v", tmdbID, err)
		return
	}

	collection := db.DB.Collection("movies")
	var existing models.Movie
	err = collection.FindOne(context.TODO(), bson.M{"tmdbId": tmdbID}).Decode(&existing)

	posterURL := "https://image.tmdb.org/t/p/w500" + tt.PosterPath
	bannerURL := "https://image.tmdb.org/t/p/original" + tt.BackdropPath

	year := 0
	if len(tt.FirstAirDate) >= 4 {
		year, _ = strconv.Atoi(tt.FirstAirDate[:4])
	}

	genres := s.getGenreNames(tt.GenreIDs)
	cast := []string{}
	if tt.Credits != nil {
		for i, c := range tt.Credits.Cast {
			if i >= 10 { break }
			cast = append(cast, c.Name)
		}
	}

	seasons := []models.Season{}
	for i := 1; i <= tt.NumberOfSeasons; i++ {
		ts, err := s.TMDB.FetchSeasonDetails(tmdbID, i)
		if err != nil {
			continue
		}

		episodes := []models.Episode{}
		for _, te := range ts.Episodes {
			episodes = append(episodes, models.Episode{
				Number:   te.EpisodeNumber,
				Title:    te.Name,
				Duration: strconv.Itoa(te.Runtime) + " min",
			})
		}

		seasons = append(seasons, models.Season{
			Number:   ts.SeasonNumber,
			Title:    ts.Name,
			Episodes: episodes,
		})
	}

	if err == mongo.ErrNoDocuments {
		tvShow := models.Movie{
			ID:           bson.NewObjectID(),
			TMDbID:       tmdbID,
			Title:        tt.Name,
			Description:  tt.Overview,
			PosterURL:    posterURL,
			BannerURL:    bannerURL,
			Rating:       tt.VoteAverage,
			Year:         year,
			Genre:        genres,
			Cast:         cast,
			IsTrending:   isTrending,
			IsFeatured:   isFeatured,
			IsTvShow:     true,
			IsPublished:  true,
			Seasons:      seasons,
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
				"genre":       genres,
				"cast":        cast,
				"isTrending":  isTrending || existing.IsTrending,
				"seasons":     seasons,
				"updatedAt":   time.Now(),
			},
		}
		_, _ = collection.UpdateOne(context.TODO(), bson.M{"tmdbId": tmdbID}, update)
	}
	cache.InvalidateMovieCache(tmdbID)
	cache.InvalidateCache("home_data")
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
