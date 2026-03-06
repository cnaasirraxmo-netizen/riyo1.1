package utils

import (
	"context"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var R2Client *s3.Client

func InitR2() {
	accessKey := os.Getenv("R2_ACCESS_KEY_ID")
	secretKey := os.Getenv("R2_SECRET_ACCESS_KEY")
	accountID := os.Getenv("R2_ACCOUNT_ID")
	endpoint := os.Getenv("R2_S3_ENDPOINT")

	if endpoint == "" && accountID != "" {
		endpoint = "https://" + accountID + ".r2.cloudflarestorage.com"
	}

	if accessKey == "" || secretKey == "" || endpoint == "" {
		log.Println("📡 R2 Storage is not fully configured.")
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
	})

	log.Println("📡 R2 Client initialized with endpoint:", endpoint)
}

func GetBaseURL() string {
	publicURL := os.Getenv("R2_PUBLIC_URL")
	if publicURL != "" {
		return publicURL
	}
	endpoint := os.Getenv("R2_S3_ENDPOINT")
	bucketName := os.Getenv("R2_BUCKET_NAME")
	return endpoint + "/" + bucketName
}
