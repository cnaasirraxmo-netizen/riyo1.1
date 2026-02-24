# Advanced TV Casting System - Architecture & Setup

## 1. Overview
The RIYO platform now includes a production-grade TV casting system supporting:
- **Google Cast (Chromecast)** for high-quality streaming to Google devices.
- **Android TV** support (via Google Cast framework).
- **DLNA / UPnP** for generic Smart TV discovery and basic streaming.
- **Riverpod State Management** for reactive UI updates and connection persistence.

## 2. Architecture (Clean Architecture)

### Domain Layer (`lib/core/casting/domain`)
- **Entities**:
  - `CastDevice`: Unified model for both Google Cast and DLNA devices.
  - `CastMedia`: Abstraction for media being casted (URL, Title, Metadata).
- **Repository Interface**: `CastingRepository` defines the contract for discovery, connection, and playback control.

### Data Layer (`lib/core/casting/data`)
- **Implementation**: `CastingRepositoryImpl` manages the simultaneous discovery from multiple SDKs:
  - `flutter_chrome_cast` for official Google protocols.
  - `media_cast_dlna` for universal discovery.
- **Device Merging**: Aggregates found devices into a single stream.

### Presentation Layer (`lib/core/casting/presentation`)
- **Providers**: `CastingNotifier` manages the state of discovery, active connections, and remote playback status.
- **Widgets**:
  - `CastingButton`: Dynamic icon that triggers discovery and shows connection state.
  - `CastDialog`: unified UI for device selection.

## 3. Setup Guide

### Android Setup
1. **Permissions**: Ensure `ACCESS_FINE_LOCATION`, `ACCESS_WIFI_STATE`, and `INTERNET` are in your `AndroidManifest.xml`.
2. **Build Settings**:
   - `minSdkVersion 21` or higher.
   - `isCoreLibraryDesugaringEnabled = true` (already configured in this project).
3. **Google Services**: The project uses `play-services-cast-framework`. Ensure your TV device is on the same WiFi network.

### iOS Setup
1. **Info.plist**:
   - Add `NSBluetoothAlwaysUsageDescription` and `NSLocalNetworkUsageDescription`.
   - Configure `Bonjour services` for `_googlecast._tcp` and `_discovery._googlecast._tcp`.

## 4. Playback Synchronization
Remote playback is controlled via the `CastingNotifier`. When a device is connected:
1. Local video is paused.
2. Media URL and metadata are sent to the TV.
3. The mobile UI switches to a "Remote Controller" mode (accessible via the Cast Dialog or Mini Controller).

## 5. Performance Optimization
- **Passive Discovery**: Discovery is triggered only when needed to save battery.
- **Background Support**: Connections persist even when the app is minimized.
- **JSON Parsing**: Discovery results are handled in real-time without blocking the main UI thread.
