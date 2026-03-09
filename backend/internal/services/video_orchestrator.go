package services

import (
	"context"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"go.mongodb.org/mongo-driver/v2/bson"
)

type VideoOrchestrator struct {
	workingDir string
}

func NewVideoOrchestrator() *VideoOrchestrator {
	dir := os.Getenv("VIDEO_WORKING_DIR")
	if dir == "" {
		dir = "./tmp/video_jobs"
	}
	os.MkdirAll(dir, 0755)
	return &VideoOrchestrator{workingDir: dir}
}

func (vo *VideoOrchestrator) CreateJob(movieID bson.ObjectID, inputURL string) (*models.VideoJob, error) {
	job := &models.VideoJob{
		ID:        bson.NewObjectID(),
		MovieID:   movieID,
		InputURL:  inputURL,
		Status:    "PENDING",
		Progress:  0,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	collection := db.DB.Collection("video_jobs")
	_, err := collection.InsertOne(context.TODO(), job)
	if err != nil {
		return nil, err
	}

	return job, nil
}

func (vo *VideoOrchestrator) ProcessJob(jobID bson.ObjectID) {
	collection := db.DB.Collection("video_jobs")

	// Update status to PROCESSING
	_, err := collection.UpdateOne(
		context.TODO(),
		bson.M{"_id": jobID},
		bson.M{"$set": bson.M{"status": "PROCESSING", "updatedAt": time.Now()}},
	)
	if err != nil {
		log.Printf("Failed to update job status: %v", err)
		return
	}

	var job models.VideoJob
	err = collection.FindOne(context.TODO(), bson.M{"_id": jobID}).Decode(&job)
	if err != nil {
		log.Printf("Failed to find job: %v", err)
		return
	}

	outputDir := filepath.Join(vo.workingDir, job.ID.Hex())
	os.MkdirAll(outputDir, 0755)
	defer os.RemoveAll(outputDir)

	// FFmpeg multi-resolution command
	// This is a simplified version of the complex ABR command
	// In production, we'd use a more sophisticated script or multiple passes
	cmd := exec.Command("ffmpeg",
		"-i", job.InputURL,
		"-filter_complex", "[0:v]split=4[v1][v2][v3][v4]; [v1]scale=w=1920:h=1080[v1out]; [v2]scale=w=1280:h=720[v2out]; [v3]scale=w=854:h=480[v3out]; [v4]scale=w=640:h=360[v4out]",
		"-map", "[v1out]", "-c:v:0", "libx264", "-b:v:0", "5000k", "-maxrate:v:0", "5350k", "-bufsize:v:0", "7500k",
		"-map", "[v2out]", "-c:v:1", "libx264", "-b:v:1", "2500k", "-maxrate:v:1", "2675k", "-bufsize:v:1", "3750k",
		"-map", "[v3out]", "-c:v:2", "libx264", "-b:v:2", "1200k", "-maxrate:v:2", "1284k", "-bufsize:v:2", "1800k",
		"-map", "[v4out]", "-c:v:3", "libx264", "-b:v:3", "800k", "-maxrate:v:3", "856k", "-bufsize:v:3", "1200k",
		"-map", "0:a", "-c:a", "aac", "-b:a", "128k", "-ac", "2",
		"-f", "hls",
		"-hls_time", "6",
		"-hls_playlist_type", "vod",
		"-hls_segment_filename", filepath.Join(outputDir, "%v/segment%03d.ts"),
		"-master_pl_name", "master.m3u8",
		"-var_stream_map", "v:0,a:0 v:1,a:0 v:2,a:0 v:3,a:0",
		filepath.Join(outputDir, "%v/playlist.m3u8"),
	)

	log.Printf("Starting FFmpeg for job %s", jobID.Hex())
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("FFmpeg failed: %v, output: %s", err, string(output))
		collection.UpdateOne(
			context.TODO(),
			bson.M{"_id": jobID},
			bson.M{"$set": bson.M{"status": "FAILED", "error": err.Error(), "updatedAt": time.Now()}},
		)
		return
	}

	// TODO: Upload to R2
	log.Printf("Job %s completed successfully (local)", jobID.Hex())

	collection.UpdateOne(
		context.TODO(),
		bson.M{"_id": jobID},
		bson.M{"$set": bson.M{"status": "COMPLETED", "progress": 100, "updatedAt": time.Now()}},
	)
}
