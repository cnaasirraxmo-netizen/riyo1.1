# Deploy: Notification Service (Go)

The RIYO Notification Service handles all user notifications, including push (FCM) and global alerts.

## Setup & Deployment

1. **Docker Build:**
   ```bash
   docker build -t riyo-notification-service -f Dockerfile .
   ```

2. **Environment Variables:**
   - `PORT`: 5004 (Default)
   - `FIREBASE_CREDS_FILE`: Path to your Firebase Service Account JSON for FCM.
   - `KAFKA_BROKERS`: Kafka broker addresses for event-driven notification triggers.

3. **Kubernetes Deployment:**
   - Deploy as a **ClusterIP** service.
   - Use as an event-driven worker for asynchronous notifications.

4. **Monitoring:**
   - Track notification delivery rates and FCM error responses.
