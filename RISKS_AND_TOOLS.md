# RIYO Architecture: Risks, Trade-offs & Recommended Tools

## 1. Risks & Trade-offs

| Component | Risk | Trade-off / Mitigation |
| :--- | :--- | :--- |
| **C++ Engine vs Platform Player** | High development & maintenance cost; requires specialized C++ talent. | Better performance, unified behavior across platforms, and direct control over hardware acceleration. |
| **Microservices Complexity** | Network overhead, complex deployment, and distributed tracing needs. | High scalability and team autonomy. Use gRPC for low-latency sync calls and Kafka for async. |
| **FFmpeg Resource Intensity** | High CPU/GPU usage during peak upload times can spike costs. | Use Spot instances for workers and implement resource-aware scheduling with a backoff queue. |
| **Database Coupling** | Risk of "Distributed Monolith" if services share the same DB. | Strict service-owned database policy. Use Event-Driven Sync (Kafka) for cross-service data consistency. |
| **DRM Integration** | Complexity of Widevine/PlayReady certification and licensing. | Use a multi-DRM vendor (e.g., PallyCon, EZDRM) for easier abstraction. |

---

## 2. Recommended Tools & Libraries

### Frontend (Flutter)
- **Networking:** `dio` or `http` with interceptors.
- **State Management:** `flutter_riverpod` (modern, testable).
- **Navigation:** `go_router` (deep linking support).
- **Storage:** `flutter_secure_storage` for tokens.

### C++ Playback Engine
- **Framework:** `FFmpeg` (Libavcodec, Libavformat).
- **Networking:** `libcurl` or `Boost.Asio`.
- **Concurrency:** `C++20` Coroutines or `std::thread`.
- **Bridge:** `Dart FFI` (direct memory access).

### Backend (Go)
- **Web Framework:** `Gin` or `Echo` (performance focused).
- **gRPC:** `Google.golang.org/grpc`.
- **ORM/SQL:** `pgx` (PostgreSQL) or `Ent` (entity-based).
- **Messaging:** `segmentio/kafka-go` or `RabbitMQ`.
- **Auth:** `Firebase Admin SDK` for Go.

### Infrastructure
- **Orchestration:** Kubernetes (EKS/GKE).
- **Monitoring:** Prometheus, Grafana, Jaeger (Tracing).
- **CI/CD:** ArgoCD (GitOps) or GitHub Actions.
- **Storage:** Cloudflare R2 (S3-compatible, no egress fees).
- **CDN:** Cloudflare (Global reach, WAF, Edge Workers).

---

## 3. Recommended Migration Plan (Node.js → Go)

1. **Phase 1 (Shadow Auth):** Implement Go API Gateway with Firebase Auth. Keep Node.js backend behind it.
2. **Phase 2 (User Service):** Extract user management from Node.js to Go. Sync via events.
3. **Phase 3 (Metadata Service):** Move movie/series listing and search to Go Metadata Service.
4. **Phase 4 (Video Ingest):** Maintain Node.js for upload, but trigger Go Video Processing via Kafka.
5. **Phase 5 (Full Transition):** Node.js remains purely as a CMS/Admin dashboard interface.
