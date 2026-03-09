package services

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/internal/utils"
	"go.mongodb.org/mongo-driver/v2/bson"
)

type VideoWorker struct {
	orchestrator *VideoOrchestrator
	r2Client     *s3.Client
	bucketName   string
}

func NewVideoWorker(vo *VideoOrchestrator, r2 *s3.Client, bucket string) *VideoWorker {
	return &VideoWorker{
		orchestrator: vo,
		r2Client:     r2,
		bucketName:   bucket,
	}
}

func (vw *VideoWorker) Start() {
	log.Println("🚀 Video Processing Worker started")
	go func() {
		for {
			vw.pollAndProcess()
			time.Sleep(10 * time.Second)
		}
	}()
}

func (vw *VideoWorker) pollAndProcess() {
	collection := db.DB.Collection("video_jobs")
	var job models.VideoJob

	// Find one pending job
	err := collection.FindOne(context.TODO(), bson.M{"status": "PENDING"}).Decode(&job)
	if err != nil {
		return // No pending jobs
	}

	log.Printf("Picking up video job %s", job.ID.Hex())

	// Process (Transcode)
	vw.orchestrator.ProcessJob(job.ID)

	// Re-fetch to check if transcoding succeeded
	err = collection.FindOne(context.TODO(), bson.M{"_id": job.ID}).Decode(&job)
	if err == nil && job.Status == "COMPLETED" {
		vw.uploadToR2(job)
	}
}

func (vw *VideoWorker) uploadToR2(job models.VideoJob) {
	outputDir := filepath.Join(vw.orchestrator.workingDir, job.ID.Hex())
	defer os.RemoveAll(outputDir)

	if vw.r2Client == nil {
		log.Printf("R2 client not initialized, skipping upload for job %s", job.ID.Hex())
		db.DB.Collection("video_jobs").UpdateOne(
			context.TODO(),
			bson.M{"_id": job.ID},
			bson.M{"$set": bson.M{"status": "FAILED", "error": "R2 Client not initialized"}},
		)
		return
	}

	err := filepath.Walk(outputDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		relPath, _ := filepath.Rel(outputDir, path)
		key := fmt.Sprintf("videos/processed/%s/%s", job.ID.Hex(), relPath)

		file, err := os.Open(path)
		if err != nil {
			return err
		}
		defer file.Close()

		contentType := "video/MP2T" // .ts
		if filepath.Ext(path) == ".m3u8" {
			contentType = "application/x-mpegURL"
		}

		_, err = vw.r2Client.PutObject(context.TODO(), &s3.PutObjectInput{
			Bucket:      aws.String(vw.bucketName),
			Key:         aws.String(key),
			Body:        file,
			ContentType: aws.String(contentType),
		})

		if err != nil {
			log.Printf("Failed to upload %s to R2: %v", key, err)
			return err
		}

		return nil
	})

	if err != nil {
		db.DB.Collection("video_jobs").UpdateOne(
			context.TODO(),
			bson.M{"_id": job.ID},
			bson.M{"$set": bson.M{"status": "FAILED", "error": "R2 Upload failed: " + err.Error()}},
		)
	} else {
		// Update movie with new master URL
		masterURL := fmt.Sprintf("%s/videos/processed/%s/master.m3u8", utils.GetBaseURL(), job.ID.Hex())
		db.DB.Collection("movies").UpdateOne(
			context.TODO(),
			bson.M{"_id": job.MovieID},
			bson.M{"$set": bson.M{"videoUrl": masterURL, "updatedAt": time.Now()}},
		)
		log.Printf("Job %s fully processed and uploaded", job.ID.Hex())
	}
}
