# RIYO Enterprise Architecture: Netflix-Style Streaming Platform

This document defines the production-grade, globally scalable architecture for the RIYO streaming platform.

---

## 1. System Overview

RIYO is a high-performance streaming platform designed for mobile (Flutter) and web (React). It combines a legacy Node.js/MongoDB CMS with a modern Go-based microservices core and a high-performance C++ video playback engine.

---

## 2. Global Architecture Diagram

```text
[ Clients ]
    ├── Flutter Mobile App (C++ Core)
    ├── React Web User App (Shaka Player)
    └── React Admin Dashboard (Node.js API)
           │
           ▼
[ Cloudflare Global CDN / WAF ]
           │
           ▼
[ API Gateway (Go) ] <───> [ Firebase Auth ]
    │ (Internal JWT, Rate Limiting, Auth Context)
    │
    ├───▶ [ User Service (Go) ] ◀───▶ [ PostgreSQL ]
    │
    ├───▶ [ Streaming Auth (Go) ] ◀───▶ [ Redis ]
    │
    ├───▶ [ Metadata Service (Go) ] ◀───▶ [ PostgreSQL + ES ]
    │
    ├───▶ [ Node.js Service ] ◀───▶ [ MongoDB ]
    │       (Admin, Upload, Legacy CMS)
    │
    └───▶ [ Recommendation (Go) ] ◀───▶ [ ClickHouse ]

[ Event Mesh ]
    └── Kafka ◀──▶ [ Video Processing (Go) ] ──▶ [ FFmpeg Pool ]
```

---

## 3. Video Processing Pipeline (Netflix-style)

| Stage | Action | Component |
| :--- | :--- | :--- |
| **Ingest** | `.mp4` Upload (1GB+) | Node.js Upload Service → R2 |
| **Trigger** | `VIDEO_UPLOADED` Event | Kafka Producer (Node.js) |
| **Worker** | Job Consumption | Video Processing Service (Go) |
| **Transcode** | 1080p, 720p, 480p, 360p | FFmpeg (x264/AAC) |
| **Packaging** | HLS Segmentation (6s) | FFmpeg (m3u8/ts) |
| **Delivery** | Processed R2 Storage | Cloudflare CDN (Edge) |

---

## 4. C++ Core Playback Engine

### A. Internal Modules
- **Demuxer:** Multi-format support (HLS/DASH/MP4).
- **Decoder:** Hardware-accelerated (MediaCodec/VideoToolbox/VAAPI).
- **ABR Controller:** Logic for seamless quality switching based on network conditions.
- **Clock Sync:** Ultra-low jitter audio-video synchronization.

### B. Flutter Integration (FFI Bridge)
```text
C++ Engine (Native) <───[ Dart FFI ]───> Flutter UI (Dart)
       │                                     │
       ▼                                     ▼
[ GPU Texture ] <───[ Texture Sharing ]─── [ Texture Widget ]
```

---

## 5. Security & Infrastructure

### Security
- **JWT:** Firebase for Identity, Internal JWT for Service-to-Service.
- **Signed URLs:** Streaming Auth issues 1-hour valid signed URLs for `.m3u8` and `.ts` files.
- **Anti-Hotlink:** Cloudflare WAF rules to prevent unauthorized playback.
- **DRM-Ready:** Engine prepared for Widevine/PlayReady (CDM abstraction).

### Infrastructure
- **Orchestration:** Kubernetes (EKS/GKE) with Helm charts.
- **Persistence:** Multi-region PostgreSQL, Redis (Caching), ClickHouse (Analytics).
- **Storage:** S3-compatible (Cloudflare R2) for cost-efficient video storage.

---

## 6. Scaling Roadmap

| Level | Strategy | Target |
| :--- | :--- | :--- |
| **MVP** | Vertical scaling, single region, Docker Compose. | < 10k Users |
| **Scale** | Horizontal scaling, Kubernetes, CDN, Redis, HPA. | 1M Users |
| **Global** | Multi-region active-active, Edge Workers, Global Accelerator. | 50M Users |

---

## 7. Performance & Cost Optimization

- **Startup Latency:** "Moov atom" at the beginning of files, predictive pre-fetching.
- **CDN Edge Tuning:** 1-month TTL for segments, 1-minute for playlists.
- **Egress Costs:** Usage of Cloudflare R2 (zero egress fees to Cloudflare CDN).
- **HPA:** Scaling transcode workers based on queue depth to optimize compute costs.

---

## 8. Enterprise Hardening Checklist

- [ ] Zero-Trust Internal Networking (Mutual TLS).
- [ ] Automated CI/CD (Blue/Green Deployment).
- [ ] Disaster Recovery Plan (15min RTO/RPO).
- [ ] Full Observability (Prometheus, Grafana, OpenTelemetry).
- [ ] PII Masking & GDPR Compliance.
