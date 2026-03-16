package handlers

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/services"
	"github.com/riyobox/backend/utils"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

var MetadataSvc *services.MetadataService
var VideoExt *services.VideoExtractor

func GetHome(c *gin.Context) {
	cached, err := cache.GetOrSetCache("home_data", cache.TrendingTTL, func() (interface{}, error) {
		collection := db.DB.Collection("movies")

		trendingMovies := []models.Movie{}
		popularMovies := []models.Movie{}
		topRatedMovies := []models.Movie{}
		trendingTV := []models.Movie{}

		opts := options.Find().SetLimit(10).SetSort(bson.M{"createdAt": -1})

		cursor, _ := collection.Find(context.TODO(), bson.M{"isTrending": true, "isTvShow": false, "isPublished": true}, opts)
		cursor.All(context.TODO(), &trendingMovies)

		cursor, _ = collection.Find(context.TODO(), bson.M{"isTvShow": false, "isPublished": true}, opts)
		cursor.All(context.TODO(), &popularMovies)

		optsRating := options.Find().SetLimit(10).SetSort(bson.M{"rating": -1})
		cursor, _ = collection.Find(context.TODO(), bson.M{"isTvShow": false, "isPublished": true}, optsRating)
		cursor.All(context.TODO(), &topRatedMovies)

		cursor, _ = collection.Find(context.TODO(), bson.M{"isTrending": true, "isTvShow": true, "isPublished": true}, opts)
		cursor.All(context.TODO(), &trendingTV)

		return gin.H{
			"trendingMovies": trendingMovies,
			"popularMovies":  popularMovies,
			"topRatedMovies": topRatedMovies,
			"latestMovies":   popularMovies, // Simplified
			"trendingTV":     trendingTV,
			"popularTV":      trendingTV, // Simplified
		}, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}

func GetMoviesByFilter(filter bson.M) gin.HandlerFunc {
	return func(c *gin.Context) {
		collection := db.DB.Collection("movies")
		opts := options.Find().SetLimit(20).SetSort(bson.M{"createdAt": -1})

		var results []models.Movie
		cursor, err := collection.Find(context.TODO(), filter, opts)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
			return
		}
		cursor.All(context.TODO(), &results)
		c.JSON(http.StatusOK, results)
	}
}

func GetMovieSources(c *gin.Context) {
	idStr := c.Param("id")
	collection := db.DB.Collection("movies")
	var movie models.Movie

	if id, err := bson.ObjectIDFromHex(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"_id": id}).Decode(&movie)
	} else if tmdbID, err := strconv.Atoi(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"tmdbId": tmdbID}).Decode(&movie)
	}

	if movie.TMDbID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
		return
	}

	cacheKey := fmt.Sprintf("movie_sources_%d", movie.TMDbID)
	cached, err := cache.GetOrSetCache(cacheKey, cache.SourcesTTL, func() (interface{}, error) {
		sources := VideoExt.ExtractSources(movie.TMDbID, movie.Title, movie.IsTvShow, 0, 0)
		subtitles := utils.GetSubtitles(movie.TMDbID, movie.IsTvShow, 0, 0)

		return gin.H{
			"sources":   sources,
			"subtitles": subtitles,
		}, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}

func GetTVSources(c *gin.Context) {
	idStr := c.Param("id")
	season, _ := strconv.Atoi(c.Param("season"))
	episode, _ := strconv.Atoi(c.Param("episode"))

	collection := db.DB.Collection("movies")
	var movie models.Movie

	if id, err := bson.ObjectIDFromHex(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"_id": id}).Decode(&movie)
	} else if tmdbID, err := strconv.Atoi(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"tmdbId": tmdbID}).Decode(&movie)
	}

	if movie.TMDbID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Not found"})
		return
	}

	cacheKey := fmt.Sprintf("tv_sources_%d_%d_%d", movie.TMDbID, season, episode)
	cached, err := cache.GetOrSetCache(cacheKey, cache.SourcesTTL, func() (interface{}, error) {
		sources := VideoExt.ExtractSources(movie.TMDbID, movie.Title, true, season, episode)
		subtitles := utils.GetSubtitles(movie.TMDbID, true, season, episode)

		return gin.H{
			"sources":   sources,
			"subtitles": subtitles,
		}, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}

func SearchMovies(c *gin.Context) {
	query := c.Query("query")

	cacheKey := fmt.Sprintf("search_%s", strings.ReplaceAll(strings.ToLower(query), " ", "_"))
	cached, err := cache.GetOrSetCache(cacheKey, cache.SearchTTL, func() (interface{}, error) {
		collection := db.DB.Collection("movies")

		filter := bson.M{
			"title": bson.M{"$regex": query, "$options": "i"},
		}

		cursor, err := collection.Find(context.TODO(), filter)
		if err != nil {
			return nil, err
		}
		defer cursor.Close(context.TODO())

		var results []models.Movie
		cursor.All(context.TODO(), &results)

		return results, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}
