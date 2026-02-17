# RIYOBOX - Firebase Integration Guide

This document outlines how Firebase is integrated into the RIYOBOX ecosystem to provide production-grade authentication, notifications, and real-time features.

## 1. Authentication (Firebase Auth)

Firebase Auth replaces the manual JWT-based system to provide more security and ease of use.

### Features
*   **Email/Password Login:** Standard registration and login.
*   **Google Sign-In:** One-tap sign-in for Android and Web.
*   **Email Verification:** Ensures users provide valid emails.
*   **Password Reset:** Secure, automated password recovery flow.
*   **Token Management:** Automatic handling of refresh tokens and session security.

### Backend Implementation
The Node.js backend uses the `firebase-admin` SDK to verify the ID tokens sent by the client (Flutter or Web).
*   **Middleware:** `authMiddleware.js` verifies the `Bearer <FirebaseIDToken>` header.
*   **User Sync:** When a user logs in via Firebase for the first time, a corresponding user record is created/synced in MongoDB to store app-specific data (watchlist, history, etc.).

---

## 2. Notifications (Firebase Cloud Messaging - FCM)

FCM is used for all push notifications across platforms.

### Use Cases
*   **Sports Updates:** Goal alerts and match starts.
*   **New Content:** Announcements for new movie releases.
*   **Subscription Alerts:** Reminders about plan expiration.
*   **Personalized Alerts:** Notifications based on "My List".

### Implementation
*   **App:** Request notification permissions and register the FCM token.
*   **Backend:** Stores user FCM tokens in MongoDB to target specific users or topics.
*   **Admin:** Dashboard to send broadcast notifications to all users.

---

## 3. Profiles & User Engagement

### Multiple Profiles per Account
To support a Netflix-like experience, each RIYOBOX account (Firebase User) can have multiple Profiles.
*   **MongoDB Schema:** The `User` record contains an array of `profiles`.
*   **Selection:** Users select their profile after logging into the account.
*   **Isolation:** Watch history and "My List" are tracked per Profile ID, not Account ID.

### GDPR Compliance
*   **Account Deletion:** Calling the deletion API removes the Firebase user account and all associated MongoDB data (history, profiles, tokens).

---

## 4. Setup Instructions

### Firebase Console Setup
1.  Create a project in [Firebase Console](https://console.firebase.google.com/).
2.  Enable **Authentication** (Email/Password and Google).
3.  Add an **Android App** (using package name `com.example.riyobox`).
4.  Download `google-services.json` and place it in `android/app/`.
5.  Generate a **Service Account Key** (JSON) and place it in `backend/config/firebase-service-account.json`.

### Environment Variables
Add the following to your backend `.env`:
*   `FIREBASE_SERVICE_ACCOUNT_PATH=config/firebase-service-account.json`

## 5. Web Platform Details

### Web User (Vite React)
1. Initialize Firebase in `web_user/src/firebase.js` using your web config object.
2. For FCM, ensure `web_user/public/firebase-messaging-sw.js` has the same config.
3. Obtain your VAPID key from the Firebase Console (Cloud Messaging tab) and add it to `requestForToken`.

### Admin Dashboard (React)
1. Initialize Firebase in `web_admin/src/utils/firebase.js`.
2. Admin authentication is also handled via Firebase. Ensure your admin email is added to the authorized list in the backend or marked as `role: 'admin'` in MongoDB.
