# RIYOBOX - Full Production Guide & Status

This document provides a comprehensive overview of the RIYOBOX system, setup instructions, and a clear list of capabilities and limitations.

## 🛠 Project Components & Status

### 1. Backend (Node.js/Express) - **STATUS: READY**
*   **Firebase Admin Integration:** Securely verifies tokens from all clients.
*   **Multi-Profile Database:** MongoDB schema supports multiple profiles per account.
*   **Notification Engine:**
    *   **Email:** Automated welcome emails via Nodemailer.
    *   **Push:** Real-time FCM notifications for match scores and new content.
*   **Sports Proxy:** Safely handles API-Football requests.

### 2. Mobile App (Flutter) - **STATUS: READY**
*   **Firebase Auth:** Integrated Login (Email/Password + Google).
*   **Profile Selection:** Netflix-style "Who's watching?" screen on startup.
*   **Sports Hub:** Live football tracking with background polling and push alerts.
*   **Personalization:** Independent history/watchlist per profile.
*   **Multi-Language:** Support for English, Somali, and Arabic.

### 3. Web User Platform (React) - **STATUS: READY**
*   **Firebase Auth:** Secure web login with Google support.
*   **Streaming:** Responsive video player for browser-based viewing.

### 4. Web Admin Dashboard (React) - **STATUS: READY**
*   **Content Management:** Upload movies to R2 storage with instant user notifications.
*   **Broadcast Center:** Send manual push alerts to all user devices.
*   **Sports Monitor:** Real-time dashboard for live match tracking.

---

## 🚀 How to Make it "Real Working" (Action Items)

To transition from the current "Mock" development mode to a live production system, follow these steps:

### 🛠 Phase 1: Firebase
1.  **Create a Firebase Project** at [console.firebase.google.com](https://console.firebase.google.com).
2.  **Auth:** Enable Email/Password and Google Sign-in providers.
3.  **Cloud Messaging:**
    *   Go to Project Settings > Cloud Messaging.
    *   Generate a **Web Push Certificate (VAPID Key)**.
4.  **Config:**
    *   **Android:** Download `google-services.json` to `android/app/`.
    *   **Web:** Copy your config object into `web_user/src/firebase.js` and `web_admin/src/utils/firebase.js`.
    *   **Service Worker:** Update the config in `web_user/public/firebase-messaging-sw.js`.
    *   **VAPID Key:** Add your VAPID key to `requestForToken` in `web_user/src/firebase.js`.
    *   **Backend:** Generate a **Service Account JSON** and save it to `backend/config/firebase-service-account.json`.

### 🛠 Phase 2: Environment Variables
Create a `.env` file in the `backend/` directory:
```env
PORT=5000
MONGO_URI=your_mongodb_atlas_uri
JWT_SECRET=any_random_secure_string

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=config/firebase-service-account.json

# Email (SMTP)
EMAIL_USER=your_gmail@gmail.com
EMAIL_PASS=your_app_specific_password

# Sports API (Get from dashboard.api-football.com)
FOOTBALL_API_KEY=your_api_football_key

# Storage (Cloudflare R2)
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET_NAME=...
R2_S3_ENDPOINT=...
```

---

## 🚫 What We CANNOT Do (Explicit Limitations)

Please be aware of the following scope limitations for this project:

1.  **Google Play/App Store Approval:** We provide the code and build configurations, but you are responsible for maintaining your own developer accounts and passing the review process.
2.  **Legal Content Hosting:** RIYOBOX is a *platform*. We do not provide movie files or copyright licenses. You must host your own legal content.
3.  **Bank Integration:** We provide hooks for Stripe and EVC Plus, but we cannot set up your merchant bank accounts or handle KYC (Know Your Customer) requirements.
4.  **Hardware Maintenance:** This is a software package. We do not provide or manage the physical servers; you must deploy this to a provider like Render, Heroku, or AWS.
5.  **DRM Key Management:** While the app can play encrypted streams, setting up a high-level DRM license server (like Widevine L1) requires a relationship with a certified DRM provider which we cannot facilitate.

---

## ❓ Common Fixes

*   **App won't build for Android:** Ensure you have Java 17 installed and that "Core Library Desugaring" is enabled in `build.gradle.kts` (we have already enabled this in the latest code).
*   **Login doesn't work:** Check the backend logs. If you see "Mock mode", it means your Firebase Service Account JSON is missing or the path in `.env` is incorrect.
