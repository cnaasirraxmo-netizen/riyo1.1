# RIYOBOX Streaming Aggregation System

This document explains how the RIYOBOX automated streaming platform works, step by step.

## 1. Metadata Synchronization (TMDb)

The system uses the **TMDb (The Movie Database) API** as the source of truth for all movie and TV show metadata.

- **Automated Sync**: A background `Scheduler` runs every 6 hours to fetch:
    - Trending Movies/TV
    - Popular Content
    - Top Rated Titles
- **Rich Data**: We fetch posters, backdrops, ratings, overview, release dates, and runtimes.
- **TV Show Hierarchy**: For TV shows, we automatically fetch all seasons and their respective episodes, building a complete database structure.
- **Deduplication**: The system checks for existing TMDb IDs in MongoDB to prevent duplicates, updating existing entries instead.

## 2. Streaming Source Aggregation

RIYOBOX does not host any video files. It aggregates links from multiple public embed providers.

- **Dynamic URL Generation**: When a user wants to watch a movie or episode, the backend dynamically generates streaming URLs using the TMDb ID.
- **Supported Providers**:
    - VidSrc
    - 2Embed
    - SuperEmbed
    - Vidsrc.pro
    - AutoEmbed
- **Extraction Logic**: The `VideoExtractor` service maps TMDb IDs to the specific URL patterns required by each provider. For TV shows, it handles Season and Episode numbering correctly.
- **Multi-Source Support**: Each title/episode is presented with multiple "Servers" (Sources), allowing users to switch if one is slow or broken.

## 3. Playback System

### Flutter (Mobile)
- **Direct Video**: Uses the custom `RiyoVideoEngine` for MP4 and HLS streams.
- **Embedded Players**: Uses `webview_flutter` to render iframe-based providers, ensuring a seamless experience even for external sources.
- **Source Selection**: A built-in menu allows users to switch between servers.

### React (Web)
- **Hybrid Player**: Automatically switches between a `<video>` tag (for direct links) and an `<iframe>` (for embed sources).
- **Responsive Controls**: Custom UI overlays for volume, progress, and source selection.

## 4. Link Health & Maintenance

- **Health Checker**: A periodic background worker sends `HTTP HEAD` requests to direct video links to ensure they are still active.
- **Broken Link Removal**: Sources that return errors (404, 500, etc.) are automatically flagged or removed from the database to ensure high availability.

## 5. Setup Instructions

1. **Backend**:
   - Set `TMDB_API_KEY` in your `.env` file.
   - Run `go run cmd/api/main.go`.
   - The scheduler will automatically start seeding data.

2. **Frontend**:
   - Flutter: `flutter run`.
   - Web: `npm run dev` inside `web_user/`.
