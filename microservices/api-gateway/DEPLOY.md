# Deploy: API Gateway (Go)

The RIYO API Gateway acts as the single entry point for all client applications, handling authentication verification and routing.

## Setup & Deployment

1. **Docker Build:**
   ```bash
   docker build -t riyo-api-gateway -f Dockerfile .
   ```

2. **Environment Variables:**
   - `PORT`: 8080 (Default)
   - `USER_SERVICE_URL`: URL for the User microservice.
   - `FIREBASE_CREDS_FILE`: Path to your Firebase Service Account JSON.
   - `INTERNAL_SECRET`: Secret for signing internal JWTs (`X-Internal-Token`).

3. **Kubernetes Deployment:**
   - Deploy as a **LoadBalancer** or via an **Ingress Controller**.
   - Use HPA (Horizontal Pod Autoscaler) based on CPU usage.

4. **Monitoring:**
   - Port 8080 exposes health checks.
   - Use Prometheus to monitor request latency and error rates.
