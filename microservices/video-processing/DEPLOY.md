# Deploy: Video Processing Service (Go)

The RIYO Video Processing Service handles video transcoding into HLS segments using FFmpeg.

## Setup & Deployment

1. **Docker Build:**
   - **Note:** The Dockerfile must include FFmpeg (e.g., `FROM alpine:latest; RUN apk add ffmpeg`).
   ```bash
   docker build -t riyo-video-processing -f Dockerfile .
   ```

2. **Environment Variables:**
   - `PORT`: 5001 (Default)
   - `R2_ACCESS_KEY_ID`: Cloudflare R2 access key.
   - `R2_SECRET_ACCESS_KEY`: Cloudflare R2 secret access key.
   - `R2_BUCKET_NAME`: Target bucket name.
   - `KAFKA_BROKERS`: Kafka broker addresses for processing jobs.

3. **Kubernetes Deployment:**
   - Deploy as a **ClusterIP** or an asynchronous **Worker Pool**.
   - Use HPA based on Kafka **Consumer Lag** (not CPU).

4. **Monitoring:**
   - Use Grafana to track transcoding success rates and average job duration.
