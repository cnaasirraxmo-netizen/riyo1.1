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
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func GetUserSettings(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)
	c.JSON(http.StatusOK, user.Settings)
}

func UpdateUserSettings(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	var settings models.UserSettings
	if err := c.ShouldBindJSON(&settings); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	collection := db.DB.Collection("users")
	_, err := collection.UpdateOne(
		context.TODO(),
		bson.M{"_id": user.ID},
		bson.M{"$set": bson.M{"settings": settings, "updatedAt": time.Now()}},
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

func GetSystemConfig(c *gin.Context) {
	collection := db.DB.Collection("system_config")
	var config models.SystemConfig
	err := collection.FindOne(context.TODO(), bson.M{}).Decode(&config)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return default if not found
			defaultConfig := models.SystemConfig{
				DownloadsEnabled: true,
				CastingEnabled:   true,
				NotificationsOn:  true,
				TrailerAutoplay:  true,
				CommentsEnabled:  true,
			}
			c.JSON(http.StatusOK, defaultConfig)
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, config)
}

func AdminUpdateSystemConfig(c *gin.Context) {
	var config models.SystemConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	config.UpdatedAt = time.Now()

	collection := db.DB.Collection("system_config")
	opts := options.Update().SetUpsert(true)
	_, err := collection.UpdateOne(
		context.TODO(),
		bson.M{},
		bson.M{"$set": config},
		opts,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, config)
}
