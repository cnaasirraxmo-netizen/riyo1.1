package handlers

import (
	"context"
	"fmt"
	"math"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func GetMovies(c *gin.Context) {
	genre := c.Query("genre")
	isTrending := c.Query("isTrending")
	isFeatured := c.Query("isFeatured")
	contentType := c.Query("contentType")
	search := c.Query("search")
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "20")

	// Create a deterministic cache key from query params
	cacheKey := fmt.Sprintf("movies_list_%s_%s_%s_%s_%s_%s_%s", genre, isTrending, isFeatured, contentType, search, pageStr, limitStr)

	cached, err := cache.GetOrSetCache(cacheKey, cache.TrendingTTL, func() (interface{}, error) {
		page, _ := strconv.Atoi(pageStr)
		limit, _ := strconv.Atoi(limitStr)

		query := bson.M{"isPublished": true}
		if genre != "" {
			query["genre"] = genre
		}
		if isTrending != "" {
			query["isTrending"] = isTrending == "true"
		}
		if isFeatured != "" {
			query["isFeatured"] = isFeatured == "true"
		}
		if contentType != "" {
			query["contentType"] = contentType
		}
		if search != "" {
			query["$or"] = []bson.M{
				{"title": bson.M{"$regex": search, "$options": "i"}},
				{"description": bson.M{"$regex": search, "$options": "i"}},
			}
		}

		skip := int64((page - 1) * limit)
		opts := options.Find().
			SetSort(bson.M{"createdAt": -1}).
			SetSkip(skip).
			SetLimit(int64(limit)).
			SetProjection(bson.M{
				"title":       1,
				"posterUrl":   1,
				"year":        1,
				"rating":      1,
				"genre":       1,
				"contentType": 1,
				"isTvShow":    1,
				"isPublished": 1,
				"status":      1,
				"accessType":  1,
				"videoUrl":    1,
			})

		collection := db.DB.Collection("movies")
		cursor, err := collection.Find(context.TODO(), query, opts)
		if err != nil {
			return nil, err
		}
		defer cursor.Close(context.TODO())

		var movies []models.Movie
		if err = cursor.All(context.TODO(), &movies); err != nil {
			return nil, err
		}

		total, _ := collection.CountDocuments(context.TODO(), query)

		return gin.H{
			"movies": movies,
			"page":   page,
			"pages":  math.Ceil(float64(total) / float64(limit)),
			"total":  total,
		}, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}

func GetComingSoonMovies(c *gin.Context) {
	cached, err := cache.GetOrSetCache("coming_soon", cache.TrendingTTL, func() (interface{}, error) {
		collection := db.DB.Collection("movies")
		opts := options.Find().SetSort(bson.M{"createdAt": -1})
		cursor, err := collection.Find(context.TODO(), bson.M{"contentType": "coming_soon"}, opts)
		if err != nil {
			return nil, err
		}
		defer cursor.Close(context.TODO())

		var movies []models.Movie
		if err = cursor.All(context.TODO(), &movies); err != nil {
			return nil, err
		}

		return movies, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}

func GetMovieByID(c *gin.Context) {
	idStr := c.Param("id")

	// We'll cache by the ID provided, but also try to resolve TMDb ID for consistent keying
	collection := db.DB.Collection("movies")
	var movie models.Movie

	// Check if it's an ObjectID or TMDb ID
	if id, err := bson.ObjectIDFromHex(idStr); err == nil {
		err = collection.FindOne(context.TODO(), bson.M{"_id": id}).Decode(&movie)
	} else if tmdbID, err := strconv.Atoi(idStr); err == nil {
		err = collection.FindOne(context.TODO(), bson.M{"tmdbId": tmdbID}).Decode(&movie)
	}

	if movie.ID.IsZero() {
		c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
		return
	}

	// Now cache using deterministic key
	prefix := "movie"
	if movie.IsTvShow {
		prefix = "tv"
	}

	cacheKey := fmt.Sprintf("%s_%s", prefix, movie.ID.Hex())
	if movie.TMDbID != 0 {
		cacheKey = fmt.Sprintf("%s_%d", prefix, movie.TMDbID)
	}

	cached, err := cache.GetOrSetCache(cacheKey, cache.MetadataTTL, func() (interface{}, error) {
		return movie, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}
