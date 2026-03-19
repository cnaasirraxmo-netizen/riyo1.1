package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/db"
	"crypto/rand"
	"fmt"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/internal/utils"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"golang.org/x/crypto/bcrypt"
)

type RegisterRequest struct {
	Name          string `json:"name" binding:"required"`
	Email         string `json:"email" binding:"required,email"`
	PhoneNumber   string `json:"phoneNumber"`
	FirebaseToken string `json:"firebaseToken" binding:"required"`
	FCMToken      string `json:"fcmToken"`
}

type LoginRequest struct {
	Email         string `json:"email" binding:"required,email"`
	FirebaseToken string `json:"firebaseToken" binding:"required"`
	FCMToken      string `json:"fcmToken"`
}

type GoogleLoginRequest struct {
	Name          string `json:"name"`
	Email         string `json:"email" binding:"required,email"`
	FirebaseToken string `json:"firebaseToken" binding:"required"`
	FCMToken      string `json:"fcmToken"`
}

type VerifyTokenRequest struct {
	IDToken string `json:"idToken" binding:"required"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type ResetPasswordRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Code        string `json:"code" binding:"required"`
	NewPassword string `json:"newPassword" binding:"required,min=6"`
}

func ForgotPassword(c *gin.Context) {
	var req ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	// Rate limiting (simple check)
	resetCollection := db.DB.Collection("password_resets")
	oneHourAgo := time.Now().Add(-1 * time.Hour)
	count, _ := resetCollection.CountDocuments(context.TODO(), bson.M{
		"email":     req.Email,
		"createdAt": bson.M{"$gt": oneHourAgo},
	})

	if count >= 5 {
		c.JSON(http.StatusTooManyRequests, gin.H{"message": "Too many reset attempts. Please try again later."})
		return
	}

	// Generate 6-digit code securely
	b := make([]byte, 3)
	if _, err := rand.Read(b); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to generate reset code"})
		return
	}
	code := fmt.Sprintf("%06d", (uint32(b[0])<<16|uint32(b[1])<<8|uint32(b[2]))%1000000)

	reset := models.PasswordReset{
		ID:        bson.NewObjectID(),
		Email:     req.Email,
		Code:      code,
		ExpiresAt: time.Now().Add(15 * time.Minute),
		IsUsed:    false,
		CreatedAt: time.Now(),
	}

	_, err := resetCollection.InsertOne(context.TODO(), reset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to generate reset code"})
		return
	}

	// Send Email
	subject := "YourApp Password Reset Code"
	body := fmt.Sprintf("Hi,\n\nYour password reset code is: %s\n\nThis code expires in 15 minutes.", code)

	go utils.SendEmail(req.Email, subject, body)

	c.JSON(http.StatusOK, gin.H{"message": "Reset code sent to your email"})
}

func ResetPassword(c *gin.Context) {
	var req ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	resetCollection := db.DB.Collection("password_resets")
	var reset models.PasswordReset
	err := resetCollection.FindOne(context.TODO(), bson.M{
		"email":  req.Email,
		"code":   req.Code,
		"isUsed": false,
		"expiresAt": bson.M{"$gt": time.Now()},
	}).Decode(&reset)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid or expired reset code"})
		return
	}

	// Update password in DB
	userCollection := db.DB.Collection("users")

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to process password"})
		return
	}

	_, err = userCollection.UpdateOne(context.TODO(), bson.M{"email": req.Email}, bson.M{
		"$set": bson.M{
			"password":  string(hashedPassword),
			"updatedAt": time.Now(),
		},
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to update password"})
		return
	}

	// Mark code as used
	resetCollection.UpdateOne(context.TODO(), bson.M{"_id": reset.ID}, bson.M{"$set": bson.M{"isUsed": true}})

	c.JSON(http.StatusOK, gin.H{"message": "Password updated successfully"})
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
		ID:          bson.NewObjectID(),
		Name:        req.Name,
		Email:       req.Email,
		PhoneNumber: req.PhoneNumber,
		Role:        "user",
		FCMTokens:   []string{},
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if req.FCMToken != "" {
		user.FCMTokens = append(user.FCMTokens, req.FCMToken)
	}

	_, err = collection.InsertOne(context.TODO(), user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	// Trigger Welcome Notification
	if req.FCMToken != "" {
		go sendWelcomeNotification(context.Background(), user.ID, []string{req.FCMToken})
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

	if req.FCMToken != "" {
		addFCMToken(context.TODO(), user.ID, req.FCMToken)
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
			FCMTokens: []string{},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		if req.FCMToken != "" {
			user.FCMTokens = append(user.FCMTokens, req.FCMToken)
		}
		_, err = collection.InsertOne(context.TODO(), user)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to create user"})
			return
		}

		// Trigger Welcome Notification
		if req.FCMToken != "" {
			go sendWelcomeNotification(context.Background(), user.ID, []string{req.FCMToken})
		}
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	} else {
		// Update FCM token for existing user
		if req.FCMToken != "" {
			addFCMToken(context.TODO(), user.ID, req.FCMToken)
		}
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

func ChangePassword(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	var req struct {
		OldPassword string `json:"oldPassword" binding:"required"`
		NewPassword string `json:"newPassword" binding:"required,min=6"`
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

	// Hash new password
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)

	collection := db.DB.Collection("users")
	_, err = collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, bson.M{"$set": bson.M{"password": string(hashedPassword), "updatedAt": time.Now()}})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to update password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
}

func DeleteAccount(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	// Delete user from DB
	_, err := db.DB.Collection("users").DeleteOne(context.TODO(), bson.M{"_id": user.ID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to delete account"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Account deleted successfully"})
}

func LogoutFromAllDevices(c *gin.Context) {
	userVal, _ := c.Get("user")
	user := userVal.(models.User)

	// Clear all FCM tokens to effectively logout from push on all devices
	_, err := db.DB.Collection("users").UpdateOne(context.TODO(), bson.M{"_id": user.ID}, bson.M{"$set": bson.M{"fcmTokens": []string{}, "updatedAt": time.Now()}})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to logout from devices"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Logged out from all devices"})
}

// Helpers

func addFCMToken(ctx context.Context, userID bson.ObjectID, token string) {
	if token == "" {
		return
	}
	collection := db.DB.Collection("users")
	collection.UpdateOne(ctx, bson.M{"_id": userID}, bson.M{"$addToSet": bson.M{"fcmTokens": token}})

	// Subscribe to "all_users" topic for broadcasts
	go utils.SubscribeToTopic(context.Background(), []string{token}, "all_users")
}

func sendWelcomeNotification(ctx context.Context, userID bson.ObjectID, tokens []string) {
	title := "Welcome to RIYO"
	message := "Enjoy your premium streaming experience!"

	// Send push
	utils.SendPushNotification(ctx, tokens, title, message, map[string]string{"type": "welcome"})

	// Save to history
	notificationCollection := db.DB.Collection("notifications")
	notification := models.Notification{
		ID:        bson.NewObjectID(),
		User:      userID,
		Title:     title,
		Message:   message,
		IsRead:    false,
		Type:      "welcome",
		Status:    "sent",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	notificationCollection.InsertOne(ctx, notification)
}
