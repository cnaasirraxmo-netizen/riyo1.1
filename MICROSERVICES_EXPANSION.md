# RIYO Enterprise Microservices Architecture (Go)

## 1. Services & Responsibilities

```text
[ Clients ] ──▶ [ API Gateway ] ◀──▶ [ Auth (Firebase) ]
           │
           ├─▶ [ User Service ] (PostgreSQL)
           ├─▶ [ Metadata Service ] (PostgreSQL + ElasticSearch)
           ├─▶ [ Streaming Auth ] (Redis)
           ├─▶ [ Recommendation Service ] (ClickHouse)
           ├─▶ [ Notification Service ] (Firebase Cloud Messaging)
           └─▶ [ Video Processing ] (Kafka + R2/S3)
```

### A. API Gateway (Go)
- **Functions:** Routing, Rate Limiting, Internal JWT issuance (`X-Internal-Token`).
- **Logic:** Injects `X-User-ID` and `X-User-Role` into headers for all internal calls.

### B. User Service (Go)
- **Functions:** Account management, profile CRUD, subscription status tracking.
- **Database:** PostgreSQL.

### C. Video Metadata Service (Go)
- **Functions:** High-speed retrieval of movie/series metadata, categories, and sections.
- **Search:** Syncs data to ElasticSearch for advanced full-text search.
- **Database:** PostgreSQL.

### D. Streaming Authorization Service (Go)
- **Functions:** Validates user permissions before issuing signed playback URLs.
- **Logic:** Integrates with Subscription Service to ensure user is active.
- **Speed:** Redis caching for sub-millisecond response times.

### E. Recommendation Service (Go)
- **Functions:** Tracks watch history, calculates "Because you watched..." algorithms.
- **Storage:** ClickHouse for fast analytical queries on millions of user events.

### F. Video Processing Service (Go)
- **Functions:** Orchestrates HLS/DASH transcoding jobs.
- **Queue:** Kafka/RabbitMQ to manage job distribution and retry logic.

### G. Notification Service (Go)
- **Functions:** Push notifications for new releases and personalized alerts.
- **Provider:** Firebase Cloud Messaging (FCM).

## 2. Communication Patterns

- **External (Client ↔ Gateway):** RESTful JSON API over HTTPS.
- **Internal (Service ↔ Service):** gRPC for synchronous calls (e.g., Auth verification).
- **Event-Driven (Service ↔ Service):** Kafka for asynchronous actions (e.g., "Video Uploaded" → "Start Transcoding").

## 3. Scalability Roadmap

| Phase | Users | Strategy |
| :--- | :--- | :--- |
| **MVP** | < 10k | Single region, Docker Compose, RDS/Managed DBs. |
| **Growth** | 10k - 1M | Kubernetes (EKS/GKE), Horizontal Pod Autoscaling (HPA), Redis Caching. |
| **Enterprise** | 1M - 50M | Multi-region, Global Accelerator, Database Sharding, Edge Computing (Workers). |

## 4. Node.js Integration (Legacy Bridge)

Node.js continues to serve:
- **Admin Panel:** Movie management, user oversight.
- **Video Upload:** Initial ingest into R2 storage.
- **CMS:** Content editing and static page management.

**Design:**
- Node.js is placed behind the Go API Gateway.
- Uses the same Internal JWT secret as Go services for auth verification.
- Emits events to the same Kafka/RabbitMQ cluster.
