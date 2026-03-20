package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

func GetProfile(c *gin.Context) {
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusOK, gin.H{
			"name": "Guest User",
			"email": "guest@riyo.app",
			"role": "user",
			"watchlist": []interface{}{},
		})
		return
	}
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	collection := db.DB.Collection("users")

	// Populate watchlist is simplified here, in Node it was .populate('watchlist')
	// In Go/Mongo driver we might need an aggregation or a second query.
	// For now, let's just return the user with movie IDs as it is in the struct.
	// To match the original behavior precisely:
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{"_id": user.ID}}},
		{{Key: "$lookup", Value: bson.M{
			"from":         "movies",
			"localField":   "watchlist",
			"foreignField": "_id",
			"as":           "watchlist",
		}}},
	}

	cursor, err := collection.Aggregate(context.TODO(), pipeline)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	defer cursor.Close(context.TODO())

	var results []bson.M
	if err = cursor.All(context.TODO(), &results); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	if len(results) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "User not found"})
		return
	}

	c.JSON(http.StatusOK, results[0])
}

func UpdateProfile(c *gin.Context) {
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusForbidden, gin.H{"message": "Please sign in to update profile"})
		return
	}
	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	user := userVal.(models.User)

	var req struct {
		Name        string `json:"name"`
		PhoneNumber string `json:"phoneNumber"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	collection := db.DB.Collection("users")
	update := bson.M{
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	if req.Name != "" {
		update["$set"].(bson.M)["name"] = req.Name
	}
	if req.PhoneNumber != "" {
		update["$set"].(bson.M)["phoneNumber"] = req.PhoneNumber
	}

	_, err := collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, update)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Profile updated"})
}

func UpdateDeviceAndLocation(c *gin.Context) {
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusOK, gin.H{"message": "Guest device not tracked"})
		return
	}
	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	user := userVal.(models.User)

	var req struct {
		DeviceInfo models.DeviceInfo   `json:"deviceInfo"`
		Location   models.LocationData `json:"location"`
		PhoneNumber string             `json:"phoneNumber"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	collection := db.DB.Collection("users")
	update := bson.M{
		"$set": bson.M{
			"deviceInfo": req.DeviceInfo,
			"location":   req.Location,
			"updatedAt":  time.Now(),
		},
	}

	if req.PhoneNumber != "" {
		update["$set"].(bson.M)["phoneNumber"] = req.PhoneNumber
	}

	_, err := collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, update)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Analytics updated"})
}

func ToggleWatchlist(c *gin.Context) {
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusForbidden, gin.H{"message": "Please sign in to manage your watchlist"})
		return
	}
	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	user := userVal.(models.User)
	movieIDStr := c.Param("movieId")
	movieID, _ := bson.ObjectIDFromHex(movieIDStr)

	collection := db.DB.Collection("users")

	// Check if already in watchlist
	inWatchlist := false
	for _, id := range user.Watchlist {
		if id == movieID {
			inWatchlist = true
			break
		}
	}

	var update bson.M
	var message string
	var isAdded bool

	if inWatchlist {
		update = bson.M{"$pull": bson.M{"watchlist": movieID}}
		message = "Removed from watchlist"
		isAdded = false
	} else {
		update = bson.M{"$push": bson.M{"watchlist": movieID}}
		message = "Added to watchlist"
		isAdded = true
	}

	_, err := collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, update)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": message, "isAdded": isAdded})
}

func ToggleNotifyMe(c *gin.Context) {
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusForbidden, gin.H{"message": "Please sign in to enable notifications"})
		return
	}
	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	user := userVal.(models.User)
	movieIDStr := c.Param("movieId")
	movieID, _ := bson.ObjectIDFromHex(movieIDStr)

	movieCollection := db.DB.Collection("movies")
	var movie models.Movie
	err := movieCollection.FindOne(context.TODO(), bson.M{"_id": movieID}).Decode(&movie)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
		return
	}

	isNotified := false
	for _, id := range movie.NotifyUsers {
		if id == user.ID {
			isNotified = true
			break
		}
	}

	var update bson.M
	var message string

	if isNotified {
		update = bson.M{"$pull": bson.M{"notifyUsers": user.ID}}
		message = "Notifications disabled"
		isNotified = false
	} else {
		update = bson.M{"$push": bson.M{"notifyUsers": user.ID}}
		message = "Notifications enabled"
		isNotified = true
	}

	_, err = movieCollection.UpdateOne(context.TODO(), bson.M{"_id": movieID}, update)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": message, "isNotified": isNotified})
}

func LogUsage(c *gin.Context) {
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusOK, gin.H{"message": "Guest usage not logged"})
		return
	}
	var log models.UsageLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	userVal, exists := c.Get("user")
	if exists {
		user := userVal.(models.User)
		log.UserID = user.ID
	}

	log.ID = bson.NewObjectID()
	log.Timestamp = time.Now()

	_, err := db.DB.Collection("usagelogs").InsertOne(context.TODO(), log)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Usage logged"})
}

func AddReview(c *gin.Context) {
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusForbidden, gin.H{"message": "Please sign in to leave a review"})
		return
	}
	movieIDStr := c.Param("id")
	movieID, _ := bson.ObjectIDFromHex(movieIDStr)

	var review models.Review
	if err := c.ShouldBindJSON(&review); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	user := userVal.(models.User)

	review.ID = bson.NewObjectID()
	review.UserID = user.ID
	review.MovieID = movieID
	review.CreatedAt = time.Now()

	_, err := db.DB.Collection("reviews").InsertOne(context.TODO(), review)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, review)
}
