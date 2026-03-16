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
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type SendNotificationRequest struct {
	Target  string   `json:"target" binding:"required"` // "all" or "specific"
	UserIDs []string `json:"userIds"`                   // For specific target
	Title   string   `json:"title" binding:"required"`
	Message string   `json:"message" binding:"required"`
}

func SendAdminNotification(c *gin.Context) {
	var req SendNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	// Use FCM Topics for broadcasting to "all" for better scalability
	if req.Target == "all" {
		go func() {
			ctx := context.Background()
			err := utils.SendToTopic(ctx, "all_users", req.Title, req.Message, map[string]string{"type": "admin"})

			status := "sent"
			if err != nil {
				status = "failed"
			}

			db.DB.Collection("notifications").InsertOne(ctx, models.Notification{
				ID:        bson.NewObjectID(),
				Title:     req.Title,
				Message:   req.Message,
				Type:      "admin",
				Status:    status,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			})
		}()

		c.JSON(http.StatusOK, gin.H{"message": "Broadcast notification queued"})
		return
	}

	// For specific users, we still use individual tokens
	go func() {
		ctx := context.Background()
		var tokens []string
		var userIDs []bson.ObjectID

		for _, idStr := range req.UserIDs {
			id, err := bson.ObjectIDFromHex(idStr)
			if err != nil {
				continue
			}
			userIDs = append(userIDs, id)

			var user models.User
			err = db.DB.Collection("users").FindOne(ctx, bson.M{"_id": id}).Decode(&user)
			if err == nil {
				tokens = append(tokens, user.FCMTokens...)
			}
		}

		if len(tokens) > 0 {
			err := utils.SendPushNotification(ctx, tokens, req.Title, req.Message, map[string]string{"type": "admin"})

			status := "sent"
			if err != nil {
				status = "failed"
			}

			history := models.Notification{
				ID:        bson.NewObjectID(),
				Title:     req.Title,
				Message:   req.Message,
				Type:      "admin",
				Status:    status,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			}
			if len(userIDs) == 1 {
				history.User = userIDs[0]
			}
			db.DB.Collection("notifications").InsertOne(ctx, history)
		}
	}()

	c.JSON(http.StatusOK, gin.H{"message": "Notifications queued for specific users"})
}

func GetNotificationHistory(c *gin.Context) {
	collection := db.DB.Collection("notifications")
	opts := options.Find().SetSort(bson.M{"createdAt": -1})
	cursor, err := collection.Find(context.TODO(), bson.M{}, opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	defer cursor.Close(context.TODO())

	var history []models.Notification
	if err := cursor.All(context.TODO(), &history); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, history)
}
