package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/pquerna/otp/totp"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"golang.org/x/crypto/bcrypt"
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
				SportsEnabled:    true,
				KidsEnabled:      true,
			}
			c.JSON(http.StatusOK, defaultConfig)
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, config)
}

func Setup2FA(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	key, err := totp.Generate(totp.GenerateOpts{
		Issuer:      "RIYO",
		AccountName: user.Email,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to generate 2FA key"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"secret": key.Secret(),
		"url":    key.URL(),
	})
}

func VerifyAndEnable2FA(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	var req struct {
		Secret string `json:"secret" binding:"required"`
		Code   string `json:"code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	valid := totp.Validate(req.Code, req.Secret)
	if !valid {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid 2FA code"})
		return
	}

	collection := db.DB.Collection("users")
	_, err := collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, bson.M{"$set": bson.M{"2faSecret": req.Secret, "updatedAt": time.Now()}})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to enable 2FA"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "2FA enabled successfully"})
}

func UpdateAdminProfile(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	var req struct {
		Username    string `json:"username"`
		Email       string `json:"email"`
		Password    string `json:"password,omitempty"`
		OldPassword string `json:"oldPassword" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	// Verify old password
	err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.OldPassword))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Incorrect old password"})
		return
	}

	collection := db.DB.Collection("users")

	// Check for unique username/email
	if req.Username != "" && req.Username != user.Username {
		count, _ := collection.CountDocuments(context.TODO(), bson.M{"username": req.Username})
		if count > 0 {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Username already taken"})
			return
		}
	}
	if req.Email != "" && req.Email != user.Email {
		count, _ := collection.CountDocuments(context.TODO(), bson.M{"email": req.Email})
		if count > 0 {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Email already in use"})
			return
		}
	}

	update := bson.M{"updatedAt": time.Now()}
	if req.Username != "" {
		update["username"] = req.Username
	}
	if req.Email != "" {
		update["email"] = req.Email
	}
	if req.Password != "" {
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		update["password"] = string(hashedPassword)
	}

	_, err = collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, bson.M{"$set": update})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to update profile"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Profile updated successfully"})
}

func AdminUpdateSystemConfig(c *gin.Context) {
	var config models.SystemConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	config.UpdatedAt = time.Now()

	collection := db.DB.Collection("system_config")
	opts := options.UpdateOne().SetUpsert(true)
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
