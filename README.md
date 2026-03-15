# RIYO - Premium Streaming App

RIYO is a production-grade movie streaming application prototype built with Flutter and Node.js. It features a modern, emoji-free UI designed for high-quality user experiences.

## 🚀 Key Features

*   **Authentication & Onboarding:** Complete flow with splash animations, multi-page onboarding, and secure login/signup.
*   **Advanced Video Player:** Custom-built player with volume/brightness gestures, playback speed controls, and quality/audio/subtitle selection.
*   **Casting:** Seamless TV casting using Google Cast SDK.
*   **Downloads & Offline Mode:** Robust download manager with progress tracking and a dedicated Offline Mode to watch saved content without internet.
*   **Admin Panel:** Secure panel for administrators to upload movies and manage content in real-time.
*   **User Web App:** A complete streaming website for users to watch content on any browser.
*   **Cloudflare R2 Storage:** Direct integration for high-performance video and image hosting with direct-to-cloud uploads.
*   **Multi-Language Support:** Global support for English, Arabic (RTL), and Somali.

## 🛠 Tech Stack

*   **Frontend:** Flutter (State management via Provider, Navigation via GoRouter).
*   **Backend:** Go, Gin framework.
*   **Database:** MongoDB (via official Go driver).
*   **Auth:** JWT (JSON Web Tokens).

## 🌍 Cloud Deployment (Render)

The backend is configured for easy deployment on [Render](https://render.com).

1.  **Connect GitHub Repository:** Connect your repository to Render.
2.  **Environment Variables:** Add the following variables in Render dashboard:
    *   `MONGO_URI`: Your MongoDB Atlas connection string.
    *   `JWT_SECRET`: A secure random string for signing tokens.
    *   `R2_ACCESS_KEY_ID`: Cloudflare R2 Access Key.
    *   `R2_SECRET_ACCESS_KEY`: Cloudflare R2 Secret Key.
    *   `R2_BUCKET_NAME`: Cloudflare R2 Bucket Name.
    *   `R2_S3_ENDPOINT`: Cloudflare R2 S3 Endpoint.
    *   `PORT`: `5000` (Render will set this automatically).
3.  **Update Frontend:** The frontend is currently pointing to `https://riyo1-1.onrender.com`. You can change this in `lib/core/constants.dart`.

## 📂 Project Structure

The RIYO platform is a comprehensive streaming ecosystem composed of a mobile application, a performant Go backend, and two web-based management and consumption portals.

### 1. Flutter Mobile App (`/lib`)
The mobile app is built with Flutter and follows a feature-driven MVVM architecture.
- **`/core`**: Global configurations, constants, theme definitions, and core logic (e.g., casting, constants).
- **`/models`**: Type-safe Dart classes representing backend data (Movie, Category, Notification, User).
- **`/presentation`**: The heart of the UI.
  - **`/screens`**: Main application views like Home, Movie Details, Video Player, Search, and Admin Panel.
  - **`/widgets`**: Reusable UI components like Movie Cards, Category Carousels, and Custom Buttons.
- **`/providers`**: State management using the Provider package (Auth, Movies, Settings, SettingsProvider).
- **`/services`**: Business logic layer for interacting with the Backend API and Google Cast/DLNA systems.

### 2. Go Backend (`/backend`)
The backend is written in Go using the high-performance Gin framework.
- **`/cmd/api`**: Entry point of the application (`main.go`).
- **`/internal`**: Contains private application logic.
  - **`/db`**: MongoDB connection setup and database seeding logic.
  - **`/handlers`**: REST API request handlers (Auth, Movies, Admin, Config, Users, Upload).
  - **`/middleware`**: Security logic (JWT Authentication, Admin RBAC, CORS).
  - **`/models`**: Go structs representing MongoDB documents.
  - **`/utils`**: Helper functions for JWT generation and Cloudflare R2 integration.
- **`Dockerfile`**: Multi-stage build configuration for containerized deployment.

### 3. Web Admin Dashboard (`/web_admin`)
A React + Vite + Tailwind CSS dashboard for content managers.
- **`/src/components`**: Modular UI elements like Sidebars, Stat Cards, and Form components.
- **`/src/pages`**: Main views including Dashboard, Movie Management, User List, and Home Layout configuration.
- **`/src/utils`**: API communication layer using Axios.

### 4. Web User Portal (`/web_user`)
A React-based streaming portal for web users.
- **`/src/components`**: Netflix-style UI components optimized for the browser.
- **`/src/pages`**: Home, Playback, and User Profile management.
- **`/src/utils`**: Backend API integration and Firebase Cloud Messaging setup.

### 5. Shared Assets & Config (`/assets`)
- Centralized storage for images, fonts, and application icons.

## ⚙️ Setup & Installation

### 1. Backend Setup
For detailed instructions on running the Go backend and MongoDB, please refer to the [Backend Setup Guide](./backend/README.md).

### 2. Frontend Setup
1.  Ensure you have Flutter installed (`flutter --version`).
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

## 🛡 Admin Panel Access

The Admin Panel is hidden from regular users and only appears for accounts with the `admin` role.

*   **Default Admin Credentials:**
    *   **Email:** `admin@example.com`
    *   **Password:** `admin123`

To access it, log in with the credentials above, go to **My RIYO** (Profile tab), and click on **Admin Panel**.

## 📺 Casting Setup
For detailed instructions on configuring TV casting for Android and iOS, see [CAST_SETUP.md](./CAST_SETUP.md).
# riyo
