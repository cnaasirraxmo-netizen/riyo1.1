package utils

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var R2Client *s3.Client

func InitR2() {
	// Re-load environment to be absolutely sure
	// godotenv.Load() is already called in main
	// Support common aliases for credentials
	accessKey := os.Getenv("R2_ACCESS_KEY_ID")
	if accessKey == "" {
		accessKey = os.Getenv("R2_ACCESS_KEY")
	}

	secretKey := os.Getenv("R2_SECRET_ACCESS_KEY")
	if secretKey == "" {
		secretKey = os.Getenv("R2_SECRET_KEY")
	}

	accountID := os.Getenv("R2_ACCOUNT_ID")
	endpoint := os.Getenv("R2_S3_ENDPOINT")

	if endpoint == "" && accountID != "" {
		endpoint = "https://" + accountID + ".r2.cloudflarestorage.com"
	}

	if endpoint != "" && !strings.HasPrefix(endpoint, "http") {
		endpoint = "https://" + endpoint
	}

	if accessKey == "" || secretKey == "" || endpoint == "" {
		log.Printf("📡 R2 Storage is not fully configured. AK: %t, SK: %t, EP: %s", accessKey != "", secretKey != "", endpoint)
		return
	}

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion("auto"),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
	)
	if err != nil {
		log.Printf("failed to load R2 config: %v", err)
		return
	}

	R2Client = s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true
	})

	log.Printf("📡 R2 Client initialized with endpoint: %s (Bucket: %s)", endpoint, GetBucketName())
}

func GetBucketName() string {
	bucket := os.Getenv("R2_BUCKET_NAME")
	if bucket == "" {
		bucket = os.Getenv("R2_BUCKET")
	}
	return bucket
}

func GetBaseURL() string {
	publicURL := os.Getenv("R2_PUBLIC_URL")
	if publicURL != "" {
		// Ensure no trailing slash
		return strings.TrimSuffix(publicURL, "/")
	}

	// Fallback to endpoint/bucket
	endpoint := os.Getenv("R2_S3_ENDPOINT")
	bucketName := GetBucketName()
	return fmt.Sprintf("%s/%s", strings.TrimSuffix(endpoint, "/"), bucketName)
}
