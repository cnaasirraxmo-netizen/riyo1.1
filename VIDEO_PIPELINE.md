# RIYO Video Processing Pipeline (ABR)

This document details the automated video transcoding and packaging pipeline for adaptive bitrate (ABR) streaming.

## 1. System Architecture

The pipeline uses a job-queue architecture orchestrated by the Go backend:

1.  **Upload**: Raw MP4 is uploaded to R2.
2.  **Job Creation**: A `VideoJob` is created in MongoDB with status `PENDING`.
3.  **Worker pickup**: The background worker picks up the job and moves it to `PROCESSING`.
4.  **Transcoding**: FFmpeg generates multiple HLS resolutions (360p, 480p, 720p, 1080p).
5.  **Packaging**: FFmpeg generates .ts segments and .m3u8 playlists.
6.  **Upload**: Processed segments are uploaded to R2 under `videos/processed/<jobID>/`.
7.  **Completion**: The `Movie` record is updated with the new master playlist URL.

## 2. FFmpeg Command Design

The core command generates a master playlist with variant streams in a single pass:

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split=4[v1][v2][v3][v4]; [v1]scale=w=1920:h=1080[v1out]; [v2]scale=w=1280:h=720[v2out]; [v3]scale=w=854:h=480[v3out]; [v4]scale=w=640:h=360[v4out]" \
  -map "[v1out]" -c:v:0 libx264 -b:v:0 5000k -maxrate:v:0 5350k -bufsize:v:0 7500k \
  -map "[v2out]" -c:v:1 libx264 -b:v:1 2500k -maxrate:v:1 2675k -bufsize:v:1 3750k \
  -map "[v3out]" -c:v:2 libx264 -b:v:2 1200k -maxrate:v:2 1284k -bufsize:v:2 1800k \
  -map "[v4out]" -c:v:3 libx264 -b:v:3 800k -maxrate:v:3 856k -bufsize:v:3 1200k \
  -map "0:a" -c:a aac -b:a 128k -ac 2 \
  -f hls \
  -hls_time 6 \
  -hls_playlist_type vod \
  -hls_segment_filename "output/%v/segment%03d.ts" \
  -master_pl_name "master.m3u8" \
  -var_stream_map "v:0,a:0 v:1,a:0 v:2,a:0 v:3,a:0" \
  "output/%v/playlist.m3u8"
```

## 3. Failure Handling

- **FFmpeg Error**: If transcoding fails, the job is marked as `FAILED` and the error is logged in the `VideoJob` document.
- **R2 Upload Error**: If uploading segments fails, the job is marked as `FAILED`.
- **Retry Logic**: The current poller picks up `PENDING` jobs. Future iterations will support automatic retry for `FAILED` jobs with an exponential backoff.

## 4. Scaling Strategy

For scaling to millions of videos:

1.  **Distributed Workers**: Move the `VideoWorker` into a separate microservice.
2.  **External Queue**: Use Redis or RabbitMQ instead of MongoDB polling.
3.  **Horizontal Autoscaling**: Scale the worker pods based on queue depth.
4.  **GPU Acceleration**: Use NVIDIA NVENC or AWS MediaConvert for faster transcoding.
5.  **Multi-region R2**: Distribute processed segments across multiple R2 buckets for lower latency.
