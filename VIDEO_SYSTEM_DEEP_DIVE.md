# RIYOBOX Video System Deep Dive

This document provides a step-by-step technical explanation of how the RIYOBOX end-to-end video extraction and playback system works, from metadata fetching to native C++ rendering on Android.

---

## 1. Metadata & Provider Discovery

Everything starts with the **TMDb (The Movie Database) ID**.

- **TMDb Sync:** The Go backend periodically fetches trending and popular content from TMDb, storing metadata (titles, years, IDs) in MongoDB.
- **Provider Registry (`backend/providers/`):** The system maintains a list of external providers (e.g., VidSrc, SuperEmbed, 2Embed). Each provider has a template for its movie and TV show URLs.
- **Dynamic Generation:** When a user selects a title, the backend generates a search query or an embed URL for each provider using the TMDb ID and titles.

## 2. The "Real Extractor" (Backend Scraping)

The goal is to find direct video streams (.m3u8, .mp4) and filter out all iframes/embeds.

### Step-by-Step Extraction (`backend/scrapers/`):
1.  **Iframe Discovery:** The `UniversalFinder` recursively searches through the initial HTML and any discovered iframes (up to depth 4).
2.  **HTML/Regex Parsing:** It uses optimized regex patterns to find video source tags, manifest URLs, and data-video attributes.
3.  **JavaScript Variable Extraction:** The system parses `<script>` tags to find hidden variables like `hls_url`, `stream_url`, or `window.config` objects that contain stream data.
4.  **JSON Config Parsing:** It identifies and deserializes JSON objects from the page (common in JWPlayer or Video.js setups) to find direct links.
5.  **Network Discovery:** It scans for AJAX endpoints or API calls (e.g., `/api/v1/get_sources`) that the provider's player might use to fetch its stream.
6.  **Redirect Following:** It follows HTTP 3xx redirects to reach the final video host.
7.  **Direct Stream Filtering:** Only URLs identified as HLS, DASH, or direct MP4/MKV are kept. All "embed" or "player" links are discarded to ensure a native experience.

## 3. Backend Streaming Proxy

Once a direct link is found, it is proxied to ensure cross-origin compatibility and privacy.

- **Proxy Handler (`ProxyStream`):** The backend serves as a gateway. It forwards client headers (like `Range` for seeking) and returns the video data, hiding the original source domain from the frontend.
- **HLS Manifest Rewriting:** For `.m3u8` playlists, the backend rewrites every line in the manifest. All segment URLs and sub-playlist URLs are converted into proxied RIYOBOX URLs, ensuring the entire stream stays within the app's control.

## 4. Native C++ Android Video Engine

RIYOBOX uses a custom, low-level video engine written in C++ for maximum performance on Android.

### Architecture (`android/app/src/main/cpp/`):
- **Network Loader:** Fetches the proxied video data from the backend.
- **Demuxer:** Parses the container format (HLS, MP4) and extracts individual video and audio packets.
- **Decoder (`MediaCodec`):** Uses Android's native `MediaCodec` API for hardware-accelerated video decoding, converting compressed packets into raw image frames.
- **Texture Renderer (`EGL/GLES`):** Manages an OpenGL context. It uploads decoded frames to a GPU texture and renders them to an Android `SurfaceTexture`.

## 5. Dart FFI Bridge & Flutter Integration

The Flutter UI communicates with the C++ engine via a high-performance bridge.

- **FFI Control (`lib/core/video_engine/riyo_video_engine.dart`):** Dart calls C++ functions directly for commands like `load()`, `play()`, `pause()`, and `seek()`.
- **Async Events:** C++ sends events (loading, buffering, ended) back to Dart via an asynchronous callback, allowing the UI to react in real-time.
- **Texture Widget:** Flutter's `Texture` widget is linked to the native C++ `SurfaceTexture` via a MethodChannel. This allows the decoded frames to be displayed directly in the Flutter widget tree with zero-copy overhead.

## 6. Error Handling & Automatic Source Switching

The system is designed for high reliability:

1.  **Native Error:** If the C++ decoder or demuxer fails to play a stream, it emits an `ERROR` event.
2.  **Dart Listener:** The `VideoPlayerScreen` listens for these events.
3.  **Automatic Fallback:** Upon receiving an error, the app immediately switches to the next available "Server" (source) in the list provided by the backend.
4.  **Seamless Transition:** This process is automatic, ensuring the user gets a working stream even if some providers are currently down.

---

This end-to-end architecture ensures that RIYOBOX provides a premium, native-feeling video experience by combining powerful backend extraction with high-performance native rendering.
