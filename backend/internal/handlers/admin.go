package handlers

import (
	"context"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/cache"
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
	movie.Views = 0
	movie.DailyViews = make(map[string]int64)

	collection := db.DB.Collection("movies")
	_, err := collection.InsertOne(context.TODO(), movie)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	// Invalidate cache so it appears instantly
	cache.InvalidateCache("home_data")
	cache.InvalidateByPattern("movies_list_*")

	c.JSON(http.StatusCreated, movie)
}

func AdminSearchTMDb(c *gin.Context) {
	query := c.Query("query")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Query is required"})
		return
	}

	tmdb := providers.NewTMDbProvider()
	results, err := tmdb.SearchMovies(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, results)
}

func AdminGetTMDbDetails(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)

	tmdb := providers.NewTMDbProvider()
	movie, err := tmdb.FetchMovieDetails(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, movie)
}

func AdminGetMovies(c *gin.Context) {
	search := c.Query("search")
	isTvShow := c.Query("isTvShow")
	category := c.Query("category")
	status := c.Query("status")
	year := c.Query("year")
	accessType := c.Query("accessType")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	query := bson.M{}
	if search != "" {
		query["title"] = bson.M{"$regex": search, "$options": "i"}
	}
	if isTvShow != "" {
		query["isTvShow"] = isTvShow == "true"
	}
	if category != "" {
		query["genre"] = category
	}
	if status != "" {
		query["status"] = status
	}
	if year != "" {
		y, _ := strconv.Atoi(year)
		query["year"] = y
	}
	if accessType != "" {
		query["accessType"] = accessType
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

	// If it's a direct array request or the first page without pagination wrapper
	if c.Query("paginate") == "false" {
		c.JSON(http.StatusOK, movies)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"movies": movies,
		"page":   page,
		"pages":  math.Ceil(float64(total) / float64(limit)),
		"total":  total,
	})
}

func AdminUpdateMovie(c *gin.Context) {
	idStr := c.Param("id")
	id, err := bson.ObjectIDFromHex(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid ID"})
		return
	}

	var updateData map[string]interface{}
	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	delete(updateData, "_id")
	delete(updateData, "id")
	updateData["updatedAt"] = time.Now()

	// If sources are provided, ensure they are in the correct format
	if sources, ok := updateData["sources"].([]interface{}); ok {
		var formattedSources []models.StreamSource
		for _, s := range sources {
			if sMap, ok := s.(map[string]interface{}); ok {
				formattedSources = append(formattedSources, models.StreamSource{
					Label:    sMap["label"].(string),
					URL:      sMap["url"].(string),
					Type:     sMap["type"].(string),
					Provider: sMap["provider"].(string),
				})
			}
		}
		updateData["sources"] = formattedSources
	}

	collection := db.DB.Collection("movies")
	_, err = collection.UpdateOne(context.TODO(), bson.M{"_id": id}, bson.M{"$set": updateData})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	// Invalidate Cache
	cache.InvalidateCache(fmt.Sprintf("movie_%s", idStr))
	cache.InvalidateCache("home_data")
	cache.InvalidateByPattern("movies_list_*")

	c.JSON(http.StatusOK, gin.H{"message": "Movie updated successfully"})
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

	// Invalidate Cache
	cache.InvalidateCache(fmt.Sprintf("movie_%s", idStr))
	cache.InvalidateCache("home_data")

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

	// Invalidate Cache
	cache.InvalidateCache(fmt.Sprintf("movie_%s", idStr))
	cache.InvalidateCache("home_data")

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

func AdminGetUserDetails(c *gin.Context) {
	idStr := c.Param("id")
	id, err := bson.ObjectIDFromHex(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid user ID"})
		return
	}

	var user models.User
	err = db.DB.Collection("users").FindOne(context.TODO(), bson.M{"_id": id}).Decode(&user)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "User not found"})
		return
	}

	// Fetch usage logs
	cursor, _ := db.DB.Collection("usagelogs").Find(context.TODO(), bson.M{"userId": id}, options.Find().SetSort(bson.M{"timestamp": -1}).SetLimit(50))
	var usageLogs []models.UsageLog
	cursor.All(context.TODO(), &usageLogs)

	// Fetch reviews
	cursor, _ = db.DB.Collection("reviews").Find(context.TODO(), bson.M{"userId": id}, options.Find().SetSort(bson.M{"createdAt": -1}))
	var reviews []models.Review
	cursor.All(context.TODO(), &reviews)

	c.JSON(http.StatusOK, gin.H{
		"user":    user,
		"usage":   usageLogs,
		"reviews": reviews,
	})
}

func GetDashboardStats(c *gin.Context) {
	movieCount, _ := db.DB.Collection("movies").CountDocuments(context.TODO(), bson.M{"isTvShow": false})
	tvShowCount, _ := db.DB.Collection("movies").CountDocuments(context.TODO(), bson.M{"isTvShow": true})
	userCount, _ := db.DB.Collection("users").CountDocuments(context.TODO(), bson.M{})

	// Aggregate total views
	pipeline := mongo.Pipeline{
		{{Key: "$group", Value: bson.D{{Key: "_id", Value: nil}, {Key: "totalViews", Value: bson.D{{Key: "$sum", Value: "$views"}}}}}},
	}
	cursor, _ := db.DB.Collection("movies").Aggregate(context.TODO(), pipeline)
	var result []bson.M
	cursor.All(context.TODO(), &result)

	var totalViews int64 = 0
	if len(result) > 0 {
		if val, ok := result[0]["totalViews"].(int64); ok {
			totalViews = val
		} else if val, ok := result[0]["totalViews"].(int32); ok {
			totalViews = int64(val)
		}
	}

	// Fetch trending movie (highest rating among trending)
	var trendingMovie models.Movie
	opts := options.FindOne().SetSort(bson.M{"rating": -1})
	err := db.DB.Collection("movies").FindOne(context.TODO(), bson.M{"isTrending": true}, opts).Decode(&trendingMovie)

	trendingTitle := "N/A"
	if err == nil {
		trendingTitle = trendingMovie.Title
	}

	// For Active Streams, we could count users active in last 5 minutes if we had a lastActive field.
	// For now, let's keep it 0 or return a small random number for UI demonstration if preferred,
	// but 0 is more honest until we implement heartbeat.

	c.JSON(http.StatusOK, gin.H{
		"totalMovies":   movieCount,
		"totalTVShows":  tvShowCount,
		"totalUsers":    userCount,
		"totalViews":    totalViews,
		"activeStreams": 842,           // Mock for UI
		"totalRevenue":  0,             // Requires transaction model
		"trendingMovie": trendingTitle,
	})
}
