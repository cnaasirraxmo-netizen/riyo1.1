# Deploy: Streaming Authorization Service (Go)

The RIYO Streaming Authorization Service manages user subscription status and signed URL generation for secure streaming.

## Setup & Deployment

1. **Docker Build:**
   ```bash
   docker build -t riyo-streaming-auth -f Dockerfile .
   ```

2. **Environment Variables:**
   - `PORT`: 5003 (Default)
   - `REDIS_HOST`: Redis host for subscription caching.
   - `S3_SECRET_KEY`: Secret key for HMAC signing of HLS master playlist URLs.
   - `INTERNAL_SECRET`: Secret for verifying internal JWTs.

3. **Kubernetes Deployment:**
   - Deploy as a **ClusterIP** service.
   - Use HPA based on high concurrency for signed URL generation.

4. **Monitoring:**
   - Track signed URL issuance rate and user subscription validation times.
