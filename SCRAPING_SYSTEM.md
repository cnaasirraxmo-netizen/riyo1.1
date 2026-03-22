# RIYO Scraping & Video Playback System

This document provides a detailed, step-by-step explanation of how the RIYO video system orchestrates content from admin uploads and automated scraping.

## 1. System Architecture Overview

The system is divided into two primary "methods" of content delivery, seamlessly integrated into a single user experience:

1.  **Admin/Official Method**: Direct video links uploaded or provided by administrators via the Riyo Admin Panel. These are prioritized for speed and reliability.
2.  **Scraping/Community Method**: Automated discovery of video links from a network of third-party providers and search engines.

---

## 2. Backend Orchestration (Go)

The core logic resides in the `VideoExtractor` service and specific API handlers.

### Step 1: Request Initiation
When a user opens a movie or episode, the Flutter app calls the `/api/v1/movie/:id/sources` (or TV equivalent) endpoint.

### Step 2: Merging Official Sources
The handler (`GetMovieSources` in `aggregation_handlers.go`) first checks the MongoDB database for:
-   `videoUrl`: The primary high-speed link.
-   `sources`: A list of alternative official servers.
These are labeled as **"Official Server"** and injected at the top of the source list.

### Step 3: Concurrent Scraping
If enabled, the `VideoExtractor` launches multiple goroutines to query various community providers in parallel:
-   **Search Providers**: Modules in `backend/providers/modules/` search third-party sites using the movie title.
-   **Embed Providers**: Discovery of links from known iframe providers (e.g., VidSrc, 2Embed).

### Step 4: Universal Discovery (The Scraper)
For every potential page found, the `UniversalFinder` is employed. It uses several methods to find the actual video file:
1.  **Fast Path**: Static HTML parsing using regex to find `.mp4`, `.m3u8`, or `.mpd` links.
2.  **Dynamic Path (Headless)**: If the fast path fails, it can launch a headless browser (using `chromedp` or `rod`) to execute JavaScript and "sniff" network traffic for the video stream.
    *   *Note: In production/deployment, this is often skipped via `DISABLE_BROWSER=true` to save RAM (512Mi limit).*

### Step 5: Validation and Ranking
The backend performs a "pre-flight" check on every discovered link:
-   It sends a `GET` request with a `Range: bytes=0-0` header to check if the link is alive.
-   It detects the content type and quality.
-   **Ranking**: Sources are sorted by Quality (4K > 1080p) and Type (Direct > HLS > DASH > Embed).

---

## 3. Frontend Integration (Flutter & C++)

### Step 1: Provider Selection
In the `MovieDetailsScreen`, sources are presented in two distinct sections:
-   **Official Servers**: Instant-play links provided by Riyo.
-   **Community Servers**: A list of providers found via scraping.

### Step 2: Instant vs. Discovery Play
-   **Admin/Local Links**: When selected, the player skips all server-finding logic and initializes the C++ engine immediately.
-   **Scraped Links**: The player may perform a final validation or extraction step before starting.

### Step 3: Native Playback (C++ Engine)
The application **does not** use the standard Flutter `video_player` package. Instead:
1.  Flutter sends the URL to the C++ engine via an **FFI (Foreign Function Interface)** bridge.
2.  The C++ engine (Android NDK) handles low-level decoding and rendering.
3.  The engine emits real-time events (`POSITION_UPDATE`, `DURATION_UPDATE`) back to Flutter to update the seekbar.

### Step 4: Offline Playback
-   Before starting any remote stream, the player checks if the movie exists in the local "downloads" directory.
-   If found, it prioritizes the local file path, allowing for **data-free offline viewing**.

---

## 4. What is Missing for "Real" Scraping?

While the system is robust, "real-world" scraping often requires additional features to handle anti-bot measures:

1.  **Residential Proxies**: Many providers block data center IPs. To work reliably at scale, the backend needs a proxy rotation system.
2.  **CAPTCHA Solvers**: Some search engines or providers require solving Cloudflare or Google CAPTCHAs, which cannot be done without specialized services.
3.  **Full HLS Segment Downloader**: Currently, the system downloads the `.m3u8` manifest. For true offline HLS, a background worker must download all `.ts` segments and rewrite the manifest paths.
4.  **Browser Fingerprinting**: To avoid detection by sophisticated anti-bot systems, the headless browsers need to mimic real user behavior (mouse movements, unique headers, varying screen resolutions).
5.  **Local Proxy Rewriter**: A system to proxy scraped links through the Riyo server to hide the user's IP from the provider and bypass CORS issues more effectively.

---

## 5. Deployment Considerations

To ensure the backend fits within a **512Mi memory limit** during deployment:
-   **Chromium is removed** from the Docker image.
-   The system relies on **Fast Path (Static)** scraping and **Admin-uploaded** links.
-   Headless scraping is reserved for local development or high-resource server environments.
