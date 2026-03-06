package handlers

import (
	"context"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func AdminCreateMovie(c *gin.Context) {
	var movie models.Movie
	if err := c.ShouldBindJSON(&movie); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	movie.ID = bson.NewObjectID()
	movie.CreatedAt = time.Now()
	movie.UpdatedAt = time.Now()
	movie.IsPublished = movie.ContentType != "coming_soon"

	collection := db.DB.Collection("movies")
	_, err := collection.InsertOne(context.TODO(), movie)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, movie)
}

func AdminGetMovies(c *gin.Context) {
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	query := bson.M{}
	if search != "" {
		query["title"] = bson.M{"$regex": search, "$options": "i"}
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

func AdminPublishMovie(c *gin.Context) {
	idStr := c.Param("id")
	id, err := bson.ObjectIDFromHex(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid movie ID"})
		return
	}

	var req struct {
		VideoURL    string `json:"videoUrl"`
		ContentType string `json:"contentType"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
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

	update := bson.M{
		"$set": bson.M{
			"videoUrl":    req.VideoURL,
			"contentType": req.ContentType,
			"isPublished": true,
			"updatedAt":   time.Now(),
		},
	}

	if req.VideoURL == "" {
		delete(update["$set"].(bson.M), "videoUrl")
	}
	if req.ContentType == "" {
		update["$set"].(bson.M)["contentType"] = "free"
	}

	_, err = collection.UpdateOne(context.TODO(), bson.M{"_id": id}, update)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	// Create notifications
	if len(movie.NotifyUsers) > 0 {
		var notifications []interface{}
		for _, userID := range movie.NotifyUsers {
			notifications = append(notifications, models.Notification{
				ID:        bson.NewObjectID(),
				User:      userID,
				Title:     "Movie Released!",
				Message:   movie.Title + " is now available to watch!",
				Movie:     movie.ID,
				IsRead:    false,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			})
		}
		db.DB.Collection("notifications").InsertMany(context.TODO(), notifications)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Movie published successfully"})
}

func AdminDeleteMovie(c *gin.Context) {
	idStr := c.Param("id")
	id, err := bson.ObjectIDFromHex(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid movie ID"})
		return
	}

	collection := db.DB.Collection("movies")
	res, err := collection.DeleteOne(context.TODO(), bson.M{"_id": id})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	if res.DeletedCount == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Movie removed"})
}

func AdminGetUsers(c *gin.Context) {
	collection := db.DB.Collection("users")
	cursor, err := collection.Find(context.TODO(), bson.M{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	defer cursor.Close(context.TODO())

	var users []models.User
	if err = cursor.All(context.TODO(), &users); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, users)
}
