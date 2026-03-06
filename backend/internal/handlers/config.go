package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// Categories

func GetCategories(c *gin.Context) {
	collection := db.DB.Collection("categories")
	opts := options.Find().SetSort(bson.M{"order": 1})
	cursor, err := collection.Find(context.TODO(), bson.M{}, opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	var categories []models.Category
	cursor.All(context.TODO(), &categories)
	c.JSON(http.StatusOK, categories)
}

func CreateCategory(c *gin.Context) {
	var cat models.Category
	c.ShouldBindJSON(&cat)
	cat.ID = bson.NewObjectID()
	cat.CreatedAt = time.Now()
	cat.UpdatedAt = time.Now()
	db.DB.Collection("categories").InsertOne(context.TODO(), cat)
	c.JSON(http.StatusCreated, cat)
}

func UpdateCategory(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := bson.ObjectIDFromHex(idStr)
	var updateData map[string]interface{}
	c.ShouldBindJSON(&updateData)
	updateData["updatedAt"] = time.Now()
	db.DB.Collection("categories").UpdateOne(context.TODO(), bson.M{"_id": id}, bson.M{"$set": updateData})
	c.JSON(http.StatusOK, gin.H{"message": "Updated"})
}

func DeleteCategory(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := bson.ObjectIDFromHex(idStr)
	db.DB.Collection("categories").DeleteOne(context.TODO(), bson.M{"_id": id})
	c.JSON(http.StatusOK, gin.H{"message": "Category deleted"})
}

func ReorderCategories(c *gin.Context) {
	var req struct {
		Items []struct {
			ID    string `json:"id"`
			Order int    `json:"order"`
		} `json:"items"`
	}
	c.ShouldBindJSON(&req)
	collection := db.DB.Collection("categories")
	for _, item := range req.Items {
		id, _ := bson.ObjectIDFromHex(item.ID)
		collection.UpdateOne(context.TODO(), bson.M{"_id": id}, bson.M{"$set": bson.M{"order": item.Order, "updatedAt": time.Now()}})
	}
	c.JSON(http.StatusOK, gin.H{"message": "Categories reordered"})
}

// Home Sections

func GetHomeSections(c *gin.Context) {
	collection := db.DB.Collection("homesections")
	opts := options.Find().SetSort(bson.M{"order": 1})
	cursor, err := collection.Find(context.TODO(), bson.M{}, opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	var sections []models.HomeSection
	cursor.All(context.TODO(), &sections)
	c.JSON(http.StatusOK, sections)
}

func CreateHomeSection(c *gin.Context) {
	var sec models.HomeSection
	c.ShouldBindJSON(&sec)
	sec.ID = bson.NewObjectID()
	sec.CreatedAt = time.Now()
	sec.UpdatedAt = time.Now()
	db.DB.Collection("homesections").InsertOne(context.TODO(), sec)
	c.JSON(http.StatusCreated, sec)
}

func UpdateHomeSection(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := bson.ObjectIDFromHex(idStr)
	var updateData map[string]interface{}
	c.ShouldBindJSON(&updateData)
	updateData["updatedAt"] = time.Now()
	db.DB.Collection("homesections").UpdateOne(context.TODO(), bson.M{"_id": id}, bson.M{"$set": updateData})
	c.JSON(http.StatusOK, gin.H{"message": "Updated"})
}

func DeleteHomeSection(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := bson.ObjectIDFromHex(idStr)
	db.DB.Collection("homesections").DeleteOne(context.TODO(), bson.M{"_id": id})
	c.JSON(http.StatusOK, gin.H{"message": "Home section deleted"})
}

func ReorderHomeSections(c *gin.Context) {
	var req struct {
		Items []struct {
			ID    string `json:"id"`
			Order int    `json:"order"`
		} `json:"items"`
	}
	c.ShouldBindJSON(&req)
	collection := db.DB.Collection("homesections")
	for _, item := range req.Items {
		id, _ := bson.ObjectIDFromHex(item.ID)
		collection.UpdateOne(context.TODO(), bson.M{"_id": id}, bson.M{"$set": bson.M{"order": item.Order, "updatedAt": time.Now()}})
	}
	c.JSON(http.StatusOK, gin.H{"message": "Sections reordered"})
}
