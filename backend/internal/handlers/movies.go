package handlers

import (
	"context"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"encoding/json"
	"fmt"
	"time"

	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/internal/utils"
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
	lastID := c.Query("lastId") // For cursor pagination
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// Try Cache first (only for non-search queries)
	cacheKey := fmt.Sprintf("movies:%s:%s:%s:%s:%s:%d", genre, isTrending, isFeatured, contentType, lastID, limit)
	if search == "" {
		if cached, _ := utils.GetCache(context.TODO(), cacheKey); cached != "" {
			var result gin.H
			json.Unmarshal([]byte(cached), &result)
			c.JSON(http.StatusOK, result)
			return
		}
	}

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

	if lastID != "" {
		oid, err := bson.ObjectIDFromHex(lastID)
		if err == nil {
			query["_id"] = bson.M{"$lt": oid} // Assuming sorted by _id or createdAt desc
		}
	}

	opts := options.Find().
		SetSort(bson.M{"_id": -1}). // Use _id for efficient cursor pagination
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

	var nextCursor string
	if len(movies) > 0 && int64(len(movies)) == int64(limit) {
		nextCursor = movies[len(movies)-1].ID.Hex()
	}

	result := gin.H{
		"movies":     movies,
		"nextCursor": nextCursor,
		"total":      total,
	}

	// Cache result
	if search == "" {
		jsonResult, _ := json.Marshal(result)
		utils.SetCache(context.TODO(), cacheKey, string(jsonResult), 5*time.Minute)
	}

	c.JSON(http.StatusOK, result)
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
	id, err := bson.ObjectIDFromHex(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid movie ID"})
		return
	}

	collection := db.DB.Collection("movies")
	var movie models.Movie
	err = collection.FindOne(context.TODO(), bson.M{"_id": id}).Decode(&movie)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, movie)
}
