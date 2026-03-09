package handlers

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/internal/utils"
	"github.com/riyobox/backend/internal/services"
	"go.mongodb.org/mongo-driver/v2/bson"
)

var VideoOrchestrator *services.VideoOrchestrator

func UploadFile(c *gin.Context) {
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "No file uploaded"})
		return
	}
	defer file.Close()

	fileName := fmt.Sprintf("%d-%s", time.Now().Unix(), strings.ReplaceAll(header.Filename, " ", "_"))
	bucketName := utils.GetBucketName()
	contentType := header.Header.Get("Content-Type")

	if utils.R2Client == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"message": "Storage service not initialized. Check server configuration."})
		return
	}

	uploader := manager.NewUploader(utils.R2Client)
	_, err = uploader.Upload(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(fileName),
		Body:        file,
		ContentType: aws.String(contentType),
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Upload failed: " + err.Error()})
		return
	}

	publicURL := fmt.Sprintf("%s/%s", utils.GetBaseURL(), fileName)

	// If it's a video, trigger a transcoding job
	if strings.HasPrefix(contentType, "video/") {
		movieIDStr := c.Query("movieId")
		if movieIDStr != "" {
			movieID, _ := bson.ObjectIDFromHex(movieIDStr)
			if VideoOrchestrator != nil {
				job, err := VideoOrchestrator.CreateJob(movieID, publicURL)
				if err == nil {
					c.JSON(http.StatusCreated, gin.H{
						"message": "Video uploaded and transcoding started",
						"url":     publicURL,
						"jobId":   job.ID,
					})
					return
				}
			}
		}
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "File uploaded successfully",
		"url":     publicURL,
		"key":     fileName,
	})
}

func UploadByURL(c *gin.Context) {
	var req struct {
		URL     string `json:"url" binding:"required"`
		MovieID string `json:"movieId"`
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
	bucketName := utils.GetBucketName()

	if utils.R2Client == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"message": "Storage service not initialized. Check server configuration."})
		return
	}

	uploader := manager.NewUploader(utils.R2Client)
	_, err = uploader.Upload(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(fileName),
		Body:        resp.Body,
		ContentType: aws.String(contentType),
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "URL upload failed: " + err.Error()})
		return
	}

	publicURL := fmt.Sprintf("%s/%s", utils.GetBaseURL(), fileName)

	// If it's a video, trigger a transcoding job
	if strings.HasPrefix(contentType, "video/") && req.MovieID != "" {
		movieID, _ := bson.ObjectIDFromHex(req.MovieID)
		if VideoOrchestrator != nil {
			job, err := VideoOrchestrator.CreateJob(movieID, publicURL)
			if err == nil {
				c.JSON(http.StatusCreated, gin.H{
					"message": "Video uploaded from URL and transcoding started",
					"url":     publicURL,
					"jobId":   job.ID,
				})
				return
			}
		}
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "File uploaded from URL successfully",
		"url":     publicURL,
		"key":     fileName,
	})
}

func ListFiles(c *gin.Context) {
	if utils.R2Client == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"message": "Storage service not initialized"})
		return
	}
	bucketName := utils.GetBucketName()
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
	bucketName := utils.GetBucketName()

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
	bucketName := utils.GetBucketName()

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
