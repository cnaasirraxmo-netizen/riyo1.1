# Deploy: Metadata Service (Go)

The RIYO Metadata Service manages all movie, series, and category metadata for the platform.

## Setup & Deployment

1. **Docker Build:**
   ```bash
   docker build -t riyo-metadata-service -f Dockerfile .
   ```

2. **Environment Variables:**
   - `PORT`: 5002 (Default)
   - `POSTGRES_HOST`: PostgreSQL database host.
   - `REDIS_HOST`: Redis host for metadata caching.
   - `INTERNAL_SECRET`: Secret for verifying internal JWTs.

3. **Kubernetes Deployment:**
   - Deploy as a **ClusterIP** service (not public).
   - Use Read Replicas for PostgreSQL to handle high-volume reads.

4. **Monitoring:**
   - Use OpenTelemetry for tracing metadata queries.
