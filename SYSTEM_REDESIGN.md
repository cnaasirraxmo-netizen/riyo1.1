# RIYO System Redesign: Unified Global Architecture

## 1. High-Level Communication Redesign

The RIYO platform is redesigned into a unified, high-performance distributed system. The **API Gateway (Go)** serves as the single entry point for all client applications (Android, Web, Admin).

```text
[ Clients ]
    ├── Android App (Flutter + C++ Engine)
    ├── Web User App (React)
    └── Admin Dashboard (React)
           │
           ▼
[ API Gateway (Go) : Port 8080 ] ◀───▶ [ Firebase Auth ]
    │ (Internal JWT, Central Auth Context)
    │
    ├───▶ [ User Service (Go) : 8081 ] ◀───▶ [ PostgreSQL ]
    │
    ├───▶ [ Metadata Service (Go) : 5002 ] ◀───▶ [ PostgreSQL + ES ]
    │
    ├───▶ [ Streaming Auth (Go) : 5003 ] ◀───▶ [ Redis ]
    │
    ├───▶ [ Notification (Go) : 5004 ] ◀───▶ [ FCM ]
    │
    └───▶ [ Node.js CMS (Express) : 5000 ] ◀───▶ [ MongoDB ]
            (Video Upload, Content Moderation, Legacy APIs)

[ Event Mesh ]
    └── Kafka ◀──▶ [ Video Processing (Go) ] ──▶ [ FFmpeg Pool ]
```

## 2. Inter-Service Communication Strategy

### A. Synchronous (gRPC)
Used for critical real-time operations between internal services.
- **Auth Verification:** User Service ↔ Streaming Auth.
- **Permission Check:** Gateway ↔ User Service.

### B. Asynchronous (Event-Driven / Kafka)
Used for non-blocking operations to ensure high availability and responsiveness.
- **Video Uploaded:** Node.js ──▶ Video Processing.
- **New Release:** Node.js/Admin ──▶ Notification Service.
- **Watch Progress:** Playback Engine ──▶ Recommendation Service.

### C. Internal JWT (`X-Internal-Token`)
Every internal request must carry an `X-Internal-Token` issued by the API Gateway. This token contains the `UID` and `Role` after Firebase verification, preventing downstream services from needing to re-verify with Firebase.

## 3. Deployment Strategy per Service

Every service is Dockerized and includes a `DEPLOY.md` in its root directory.

- **Orchestration:** Docker Compose (Development) / Kubernetes (Production).
- **Service Discovery:** Kubernetes CoreDNS or Consul.
- **Config Management:** Centralized via environment variables (Viper in Go, Dotenv in Node.js).
