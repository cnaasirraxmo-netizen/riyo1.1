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
	"github.com/pquerna/otp/totp"
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
	Identifier    string `json:"identifier" binding:"required"` // Email or Username
	Password      string `json:"password"`
	FirebaseToken string `json:"firebaseToken"`
	FCMToken      string `json:"fcmToken"`
	RememberMe    bool   `json:"rememberMe"`
	TwoFACode     string `json:"2faCode"`
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

	// Integration with Firebase for sending reset links (via SDK if possible)
	// For this task, we will send the code via our email utility
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

	collection := db.DB.Collection("users")
	var user models.User
	err := collection.FindOne(context.TODO(), bson.M{
		"$or": []bson.M{
			{"email": req.Identifier},
			{"username": req.Identifier},
		},
	}).Decode(&user)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid credentials"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Database error"})
		return
	}

	// Check if account is locked
	if user.LockedUntil != nil && user.LockedUntil.After(time.Now()) {
		c.JSON(http.StatusForbidden, gin.H{"message": fmt.Sprintf("Account locked until %v", user.LockedUntil.Format(time.RFC822))})
		return
	}

	// Admin login with password
	if user.Role == "admin" && req.Password != "" {
		err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password))
		if err != nil {
			// Increment login attempts
			newAttempts := user.LoginAttempts + 1
			update := bson.M{"$set": bson.M{"loginAttempts": newAttempts}}
			if newAttempts >= 5 {
				lockTime := time.Now().Add(15 * time.Minute)
				update["$set"].(bson.M)["lockedUntil"] = lockTime
				// Log suspicious activity
				fmt.Printf("[SECURITY] Account %s locked due to too many failed attempts\n", user.Email)
			}
			collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, update)
			c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid credentials"})
			return
		}

		// Check 2FA if enabled
		if user.TwoFASecret != "" {
			if req.TwoFACode == "" {
				c.JSON(http.StatusOK, gin.H{"require2FA": true})
				return
			}
			valid := totp.Validate(req.TwoFACode, user.TwoFASecret)
			if !valid {
				c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid 2FA code"})
				return
			}
		}
	} else if req.FirebaseToken != "" {
		// Regular user login with Firebase
		_, err := utils.VerifyFirebaseToken(req.FirebaseToken)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid Firebase token"})
			return
		}
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Authentication method not provided"})
		return
	}

	// Success: Reset attempts and update last login
	now := time.Now()
	collection.UpdateOne(context.TODO(), bson.M{"_id": user.ID}, bson.M{
		"$set": bson.M{
			"loginAttempts": 0,
			"lastLogin":      now,
			"lockedUntil":    nil,
		},
	})

	if req.FCMToken != "" {
		addFCMToken(context.TODO(), user.ID, req.FCMToken)
	}

	duration := time.Hour
	if req.RememberMe {
		duration = time.Hour * 24 * 30
	}

	token, err := utils.GenerateTokenWithDuration(user.ID, duration)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"_id":      user.ID,
		"name":     user.Name,
		"username": user.Username,
		"email":    user.Email,
		"role":     user.Role,
		"token":    token,
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
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusForbidden, gin.H{"message": "Please sign in to change password"})
		return
	}
	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
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
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusForbidden, gin.H{"message": "Guest accounts cannot be deleted"})
		return
	}
	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
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
	if isGuest, _ := c.Get("isGuest"); isGuest == true {
		c.JSON(http.StatusOK, gin.H{"message": "Guest logged out"})
		return
	}
	userVal, ok := c.Get("user")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
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
