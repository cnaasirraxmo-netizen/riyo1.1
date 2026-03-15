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
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func GetMovies(c *gin.Context) {
	genre := c.Query("genre")
	isTrending := c.Query("isTrending")
	isFeatured := c.Query("isFeatured")
	contentType := c.Query("contentType")
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

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
		SetLimit(int64(limit))

	collection := db.DB.Collection("movies")
	cursor, err := collection.Find(context.TODO(), query, opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	defer cursor.Close(context.TODO())

	var movies []models.Movie
	if err = cursor.All(context.TODO(), &movies); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	total, _ := collection.CountDocuments(context.TODO(), query)

	c.JSON(http.StatusOK, gin.H{
		"movies": movies,
		"page":   page,
		"pages":  math.Ceil(float64(total) / float64(limit)),
		"total":  total,
	})
}

func GetComingSoonMovies(c *gin.Context) {
	collection := db.DB.Collection("movies")
	opts := options.Find().SetSort(bson.M{"createdAt": -1})
	cursor, err := collection.Find(context.TODO(), bson.M{"contentType": "coming_soon"}, opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	defer cursor.Close(context.TODO())

	var movies []models.Movie
	if err = cursor.All(context.TODO(), &movies); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, movies)
}

func GetMovieByID(c *gin.Context) {
	idStr := c.Param("id")

	cacheKey := fmt.Sprintf("movie_%s", idStr)
	cached, err := cache.GetOrSetCache(cacheKey, cache.MetadataTTL, func() (interface{}, error) {
		id, err := bson.ObjectIDFromHex(idStr)
		if err != nil {
			return nil, fmt.Errorf("Invalid movie ID")
		}

		collection := db.DB.Collection("movies")
		var movie models.Movie
		err = collection.FindOne(context.TODO(), bson.M{"_id": id}).Decode(&movie)
		if err != nil {
			return nil, err
		}
		return movie, nil
	})

	if err != nil {
		if err.Error() == "Invalid movie ID" {
			c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
			return
		}
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}
