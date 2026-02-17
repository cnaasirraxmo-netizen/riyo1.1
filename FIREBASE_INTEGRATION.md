# RIYOBOX - Firebase & Backend Integration Guide

This guide provides a complete walkthrough for fixing "Firebase not found" errors and ensuring successful deployment on platforms like Render.com.

## 1. Backend Fixes (Summary)

We have implemented the following critical fixes in the Node.js backend:

- **OverwriteModelError Fix**: The `User` model now uses `mongoose.models.User || mongoose.model('User', userSchema)` to prevent re-compilation errors.
- **Duplicate Key Error Fix**: `firebaseUid` now uses a `sparse: true` index. This allows multiple users to have a `null` UID (standard email/pass users) without causing index collisions.
- **Firebase Initialization**: The backend now supports `FIREBASE_SERVICE_ACCOUNT_JSON` as a raw JSON string in environment variables. This is the **recommended** way for Render.com.
- **Unified Auth**: Both standard JWT and Firebase tokens are supported.

---

## 2. Backend Deployment (Render.com)

To deploy successfully, set these **Environment Variables** in the Render Dashboard:

| Key | Value (Example) |
|---|---|
| `MONGO_URI` | `mongodb+srv://user:pass@cluster.mongodb.net/riyobox` |
| `JWT_SECRET` | `your_long_random_secret_string` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `{"type": "service_account", "project_id": "...", ...}` (The full content of your JSON file) |
| `NODE_ENV` | `production` |

> **Pro Tip**: If using `FIREBASE_SERVICE_ACCOUNT_JSON`, make sure the JSON string is valid and contains no hidden newlines that might break the parser.

---

## 3. Flutter Integration (Fixing "Firebase not found")

If your Flutter app shows "Firebase not found" or "Firebase has not been initialized", follow these steps:

### Step A: Configuration Files
1. **Android**: Download `google-services.json` from Firebase Console and place it in `android/app/`.
2. **iOS**: Download `GoogleService-Info.plist` and place it in `ios/Runner/` using Xcode.

### Step B: Plugin Setup
Ensure your `pubspec.yaml` has:
```yaml
dependencies:
  firebase_core: ^3.10.1
  firebase_auth: ^5.4.1
  firebase_messaging: ^15.2.0
```

### Step C: Initialization (CRITICAL)
Your `lib/main.dart` **must** look like this:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // This is where most "Firebase not found" errors happen
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  runApp(MyApp());
}
```

### Step D: Common Causes of Failure
1. **Package Name Mismatch**: The `package name` in `android/app/build.gradle` must **exactly** match the one in Firebase Console.
2. **Missing SHA-1 Key**: For Google Sign-In or Phone Auth, you must add your debug and release SHA-1 fingerprints to the Firebase project settings.
3. **Multidex Not Enabled**: If your app crashes on startup, ensure `multiDexEnabled true` is set in `android/app/build.gradle`.

---

## 4. Verification Flow

1. **Backend**: Check the logs. You should see `✅ Firebase Admin initialized using JSON string`.
2. **Flutter**: Check the debug console for `✅ Firebase initialized successfully`.
3. **Registration**: Try registering an account via the app. The backend should successfully sync the user even if they don't have a `firebaseUid` yet.
