# RIYO Integrated System Design: Multi-Platform Flow

This document details how the various platform components (Android, Web, Admin, and Microservices) work together in the redesigned RIYO ecosystem.

## 1. User Lifecycle Flow

### Authentication (All Platforms)
1. **Login**: User logs in via Firebase Auth on Android/Web.
2. **ID Token**: Client receives a Firebase ID Token.
3. **Gateway Request**: Client sends ID Token to the **Go API Gateway**.
4. **Internal Token**: Gateway verifies ID Token and issues a short-lived Internal JWT (`X-Internal-Token`).
5. **Context Injection**: Gateway injects `X-User-ID` and `X-User-Role` into headers for downstream microservices.

### Content Discovery
1. **Metadata Service**: Android/Web apps query the Metadata microservice (via Gateway) for movie lists, categories, and featured content.
2. **Search**: High-speed search is powered by ElasticSearch within the Metadata Service.

### Secure Playback
1. **Authorization**: Before playback, the Android/Web app requests a signed URL from the **Streaming Auth Service**.
2. **Validation**: The service checks user subscription (via Redis/Postgres) and permission for the specific content.
3. **Signed URL**: If authorized, the service returns a signed HLS master playlist URL (e.g., Cloudflare R2 signature).
4. **Playback Engine (C++)**: The Android app's C++ core engine consumes the signed URL, handles ABR switching, and renders via GPU.

## 2. Admin Content Lifecycle

### Content Ingest
1. **Admin Panel**: Administrator uploads a video via the React Admin Dashboard.
2. **Upload Service (Node.js)**: The Node.js microservice receives the file and stores it in the Raw R2 Bucket.
3. **Event Trigger**: Node.js emits a `VIDEO_UPLOADED` event to **Kafka**.

### Automated Processing
1. **Worker Job**: The **Video Processing Service** consumes the Kafka event.
2. **Transcoding**: FFmpeg generates HLS renditions (1080p, 720p, 480p, 360p).
3. **Master Playlist**: The service generates the `master.m3u8` and variant playlists.
4. **Completion Event**: Once finished, the service updates the movie status in the database.

### User Notification
1. **Publication**: When the admin publishes a "Coming Soon" title.
2. **Notification Service**: Sends push notifications (via FCM) to all users who tapped "Notify Me".

## 3. Communication Protocols

| Source | Target | Protocol | Purpose |
| :--- | :--- | :--- | :--- |
| **Android/Web** | **API Gateway** | REST/JSON (HTTPS) | Public/Private API entry. |
| **Gateway** | **Internal Services** | HTTP/gRPC | Internal service calls. |
| **Admin Panel** | **Node.js CMS** | REST/JSON | Content management. |
| **Node.js** | **Video Processing** | Kafka | Asynchronous job trigger. |
| **Microservices** | **Databases** | SQL/NoSQL | Persistence (Postgres, Mongo, Redis). |
