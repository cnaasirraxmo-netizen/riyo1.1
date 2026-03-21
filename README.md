# RIYO - Premium Full-Stack Streaming Ecosystem

RIYO is a production-grade movie streaming ecosystem designed for high-performance and secure content delivery. It features a cross-platform Flutter mobile application, a high-concurrency Go backend, and modern React-based web portals for both users and administrators.

## 🚀 Key Features

*   **Secure Admin System**: Full-stack admin management with 2FA (Google Authenticator), account lockout after failed attempts, and secure profile management.
*   **High-Performance Video Player**: Custom-built C++ native engine (Android) for smooth playback of high-bitrate content, including HLS (.m3u8), DASH, and direct MP4.
*   **MX Player Style Link Detection**: Advanced scraping and link detection system that automatically discovers, validates, and plays working video sources from various providers.
*   **Unified Push Notifications**: Integrated Firebase Messaging system for instant welcome messages and administrative broadcasts.
*   **Casting & Downloads**: Seamless TV casting via Google Cast SDK and a robust download manager for offline viewing.
*   **Cloud-Native Storage**: Direct integration with Cloudflare R2 for high-performance video hosting and image assets.
*   **Multi-Language Support**: Fully localized for English and Somali.

## 🛠 Tech Stack

- **Mobile**: Flutter (Provider for state management, GoRouter for navigation).
- **Backend**: Go (Gin Framework, MongoDB official driver).
- **Admin & Web**: React (Vite, Tailwind CSS, Axios).
- **Video Engine**: Custom C++ engine using MediaNDK and EGL/GLES for hardware-accelerated rendering.
- **Infrastructure**: MongoDB, Redis (Caching), Cloudflare R2 (Storage), Firebase (Auth/Push).

## 📂 Project Structure

### 1. Flutter Mobile App (`/lib`)
Feature-driven MVVM architecture.
- **`/core`**: Global configurations, constants, theme, and the C++ video engine bridge.
- **`/presentation`**: UI layer featuring screens for streaming, search, downloads, and user settings.
- **`/providers`**: Centralized state management (Auth, Settings, Playback).
- **`/services`**: Business logic for API communication and notification handling.

### 2. Go Backend (`/backend`)
High-performance REST API.
- **`/internal/handlers`**: API endpoints for movies, users, auth, and admin controls.
- **`/internal/middleware`**: Security layer including JWT protection and Admin-only RBAC.
- **`/providers`**: Concurrent scraping system for discovering video sources across multiple providers.
- **`/scrapers`**: Modular extraction engine for HTML, JS, and JSON parsing.

### 3. Web Admin Dashboard (`/web_admin`)
React-based management portal.
- **Dashboard**: Real-time stats and content overview.
- **Movie Management**: TMDb-integrated metadata fetching and video source configuration.
- **Settings**: Secure profile management and 2FA setup.

### 4. Web User Portal (`/web_user`)
A Netflix-style streaming experience for browsers.

## ⚙️ Setup & Installation

### 1. Backend Setup
1.  Configure your `.env` file (see `.env.example`).
2.  Install Go dependencies: `cd backend && go mod download`.
3.  Run the server: `go run cmd/api/main.go`.

### 2. Frontend Setup (Flutter)
1.  Ensure Flutter is installed.
2.  Install dependencies: `flutter pub get`.
3.  Run the application: `flutter run`.

## 🛡 Admin Panel Access

The system automatically initializes a default admin user on first startup.

- **Username**: `sahan`
- **Password**: `sahan00`
- **Email**: `aabahatechnologyada@gmail.com`

**Important**: Change these credentials immediately via the **Settings** page after your first login.

## 📺 Documentation
- [Admin Setup & Security](./ADMIN_SETUP.md)
- [Video System Deep Dive](./STREAMING_SYSTEM.md)
- [Casting Configuration](./CAST_SETUP.md)
- [Environment Variables](./.env.example)

---
Developed with ❤️ by the RIYO Team.
