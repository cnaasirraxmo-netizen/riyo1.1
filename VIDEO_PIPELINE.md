# RIYO Video Processing Pipeline Architecture

## 1. High-Level Flow

```text
[ Admin Panel ] ──▶ [ Node.js Upload Service ] ──▶ [ R2 Bucket (Source) ]
                               │
                               ▼
                        [ Kafka / RabbitMQ ]
                               │
                               ▼
                  [ Go Video Processing Service ]
                               │
          ┌────────────────────┴────────────────────┐
          ▼                                         ▼
   [ Job Scheduler ]                        [ Progress Tracker ] ──▶ [ Redis ]
          │                                         │
          ▼                                         ▼
   [ Worker Pool (FFmpeg) ]                 [ Webhook / Socket.io ] ──▶ [ Admin UI ]
          │
          ├─▶ Transcode: 1080p, 720p, 480p, 360p
          ├─▶ Extract: Audio (AAC), Subtitles (VTT)
          ├─▶ Generate: HLS Segments (.ts), Master Playlist (.m3u8)
          └─▶ Create: Thumbnail Sprites, Metadata JSON
          │
          ▼
   [ R2 Bucket (Processed) ] ──▶ [ Cloudflare / CloudFront CDN ]
```

## 2. Detailed Component Specifications

### A. Input & Trigger
- **Source:** Node.js backend receives `.mp4` and uploads to `uploads/raw/<uuid>.mp4`.
- **Event:** Node.js emits a `VIDEO_UPLOADED` event to Kafka with metadata (jobId, sourceKey, resolutions).

### B. Go Video Processing Service (Worker)
- **Architecture:** Go-based orchestrator using `os/exec` for FFmpeg or a C wrapper.
- **Scaling:** Horizontal Pod Autoscaler (HPA) based on queue depth.
- **Idempotency:** Checks `processed/<filename>/master.m3u8` existence before starting.

### C. FFmpeg Transcoding Profile
```bash
# Example command for 1080p HLS
ffmpeg -i input.mp4 \
  -c:v libx264 -preset fast -crf 23 -g 48 -keyint_min 48 -sc_threshold 0 \
  -map 0:v:0 -s:v:0 1920x1080 -b:v:0 5000k \
  -c:a aac -b:a 128k -ac 2 \
  -f hls -hls_time 6 -hls_playlist_type pill -hls_segment_filename "1080p_%03d.ts" 1080p.m3u8
```
- **Keyframe Interval:** 2 seconds (assuming 24fps, `-g 48`).
- **Segment Length:** 6 seconds (`-hls_time 6`).

### D. Output Structure
```text
/videos/processed/<movie_id>/
  ├── master.m3u8
  ├── 1080p/
  │    ├── index.m3u8
  │    └── seg_001.ts ...
  ├── 720p/
  │    ├── index.m3u8
  │    └── seg_001.ts ...
  ├── thumbnails/
  │    ├── sprite.jpg
  │    └── index.vtt
  └── report.json
```

### E. CDN Optimization
- **Caching:**
    - `.ts` files: Cache for 1 month (immutable).
    - `.m3u8` files: Cache for 1 minute (allows for dynamic playlist updates).
- **Security:** Signed URLs for all playlist and segment requests via Go Streaming Auth Service.
