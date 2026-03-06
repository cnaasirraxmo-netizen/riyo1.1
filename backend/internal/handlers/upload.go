package handlers

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/utils"
)

func UploadFile(c *gin.Context) {
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "No file uploaded"})
		return
	}
	defer file.Close()

	fileName := fmt.Sprintf("%d-%s", time.Now().Unix(), strings.ReplaceAll(header.Filename, " ", "_"))
	bucketName := os.Getenv("R2_BUCKET_NAME")

	_, err = utils.R2Client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(fileName),
		Body:        file,
		ContentType: aws.String(header.Header.Get("Content-Type")),
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	publicURL := fmt.Sprintf("%s/%s", utils.GetBaseURL(), fileName)

	c.JSON(http.StatusCreated, gin.H{
		"message": "File uploaded successfully",
		"url":     publicURL,
		"key":     fileName,
	})
}

func UploadByURL(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "URL is required"})
		return
	}

	resp, err := http.Get(req.URL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	defer resp.Body.Close()

	contentType := resp.Header.Get("Content-Type")
	ext := "jpg"
	if parts := strings.Split(contentType, "/"); len(parts) > 1 {
		ext = parts[1]
	}
	fileName := fmt.Sprintf("url-%d.%s", time.Now().Unix(), ext)
	bucketName := os.Getenv("R2_BUCKET_NAME")

	_, err = utils.R2Client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(fileName),
		Body:        resp.Body,
		ContentType: aws.String(contentType),
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	publicURL := fmt.Sprintf("%s/%s", utils.GetBaseURL(), fileName)

	c.JSON(http.StatusCreated, gin.H{
		"message": "File uploaded from URL successfully",
		"url":     publicURL,
		"key":     fileName,
	})
}

func ListFiles(c *gin.Context) {
	bucketName := os.Getenv("R2_BUCKET_NAME")
	output, err := utils.R2Client.ListObjectsV2(context.TODO(), &s3.ListObjectsV2Input{
		Bucket: aws.String(bucketName),
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	var files []gin.H
	baseURL := utils.GetBaseURL()
	for _, obj := range output.Contents {
		files = append(files, gin.H{
			"key":          *obj.Key,
			"size":         obj.Size,
			"lastModified": obj.LastModified,
			"url":          fmt.Sprintf("%s/%s", baseURL, *obj.Key),
		})
	}

	c.JSON(http.StatusOK, files)
}

func DeleteFile(c *gin.Context) {
	key := c.Param("key")
	bucketName := os.Getenv("R2_BUCKET_NAME")

	_, err := utils.R2Client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(key),
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "File deleted successfully"})
}

func GetSignedURL(c *gin.Context) {
	key := c.Param("key")
	bucketName := os.Getenv("R2_BUCKET_NAME")

	// AWS SDK v2 presign client
	presignClient := s3.NewPresignClient(utils.R2Client)
	presignedReq, err := presignClient.PresignGetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(key),
	}, s3.WithPresignExpires(time.Hour))

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"url": presignedReq.URL})
}
