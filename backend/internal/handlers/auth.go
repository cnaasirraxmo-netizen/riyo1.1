package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/internal/utils"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type RegisterRequest struct {
	Name          string `json:"name" binding:"required"`
	Email         string `json:"email" binding:"required,email"`
	FirebaseToken string `json:"firebaseToken" binding:"required"`
}

type LoginRequest struct {
	Email         string `json:"email" binding:"required,email"`
	FirebaseToken string `json:"firebaseToken" binding:"required"`
}

type GoogleLoginRequest struct {
	Name          string `json:"name"`
	Email         string `json:"email" binding:"required,email"`
	FirebaseToken string `json:"firebaseToken" binding:"required"`
}

type VerifyTokenRequest struct {
	IDToken string `json:"idToken" binding:"required"`
}

func VerifyToken(c *gin.Context) {
	var req VerifyTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	fbToken, err := utils.VerifyFirebaseToken(req.IDToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid or expired Firebase token"})
		return
	}

	// Extract claims
	email, _ := fbToken.Claims["email"].(string)
	name, _ := fbToken.Claims["name"].(string)

	c.JSON(http.StatusOK, gin.H{
		"uid":   fbToken.UID,
		"email": email,
		"name":  name,
	})
}

func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	// Verify Firebase Token
	fbToken, err := utils.VerifyFirebaseToken(req.FirebaseToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid Firebase token"})
		return
	}

	collection := db.DB.Collection("users")
	var existingUser models.User
	err = collection.FindOne(context.TODO(), bson.M{"email": req.Email}).Decode(&existingUser)
	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "User already exists"})
		return
	}

	user := models.User{
		ID:        bson.NewObjectID(),
		Name:      req.Name,
		Email:     req.Email,
		Role:      "user",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	_, err = collection.InsertOne(context.TODO(), user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	token, err := utils.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"_id":   user.ID,
		"name":  user.Name,
		"email": user.Email,
		"role":  user.Role,
		"token": token,
		"uid":   fbToken.UID,
	})
}

func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	// Verify Firebase Token
	fbToken, err := utils.VerifyFirebaseToken(req.FirebaseToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid Firebase token"})
		return
	}

	collection := db.DB.Collection("users")
	var user models.User
	err = collection.FindOne(context.TODO(), bson.M{"email": req.Email}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusUnauthorized, gin.H{"message": "User not found in database"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	token, err := utils.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"_id":   user.ID,
		"name":  user.Name,
		"email": user.Email,
		"role":  user.Role,
		"token": token,
		"uid":   fbToken.UID,
	})
}

func GoogleLogin(c *gin.Context) {
	var req GoogleLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	// Verify Firebase Token
	fbToken, err := utils.VerifyFirebaseToken(req.FirebaseToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid Firebase token"})
		return
	}

	collection := db.DB.Collection("users")
	var user models.User
	err = collection.FindOne(context.TODO(), bson.M{"email": req.Email}).Decode(&user)

	if err == mongo.ErrNoDocuments {
		// Auto-register Google user
		user = models.User{
			ID:        bson.NewObjectID(),
			Name:      req.Name,
			Email:     req.Email,
			Role:      "user",
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		_, err = collection.InsertOne(context.TODO(), user)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to create user"})
			return
		}
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	token, err := utils.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"_id":   user.ID,
		"name":  user.Name,
		"email": user.Email,
		"role":  user.Role,
		"token": token,
		"uid":   fbToken.UID,
	})
}
