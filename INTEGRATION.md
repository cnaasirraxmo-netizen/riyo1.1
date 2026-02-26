# Frontend Integration Guide: RIYO Microservices

This guide explains how to integrate the Flutter (Mobile) and React (Web) applications with the new Go-based User Management Microservice and Firebase Authentication.

---

## 📱 Flutter Integration (Mobile)

### 1. Authentication Service
Create a dedicated service to handle Firebase Login and Token retrieval.

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String gatewayUrl = "https://api.riyo.com/v1";

  // Login with Email/Password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Sync with our User Microservice
      await syncUserWithBackend(result.user);

      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Get Firebase ID Token and Sync
  Future<void> syncUserWithBackend(User? user) async {
    if (user == null) return;

    String? idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse("$gatewayUrl/users/sync"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      },
      body: jsonEncode({
        "firebase_id": user.uid,
        "email": user.email,
        "name": user.displayName ?? "",
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to sync user with backend");
    }
  }
}
```

### 2. HTTP Interceptor
Use an interceptor to automatically attach the ID Token to every request.

```dart
class ApiClient {
  static Future<Map<String, String>> getHeaders() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<http.Response> get(String path) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse("https://api.riyo.com/v1$path"), headers: headers);

    if (response.statusCode == 401) {
      // Handle Token Expiry or Suspension
      handleUnauthorized();
    }
    return response;
  }
}
```

---

## 💻 React Integration (Web & Admin)

### 1. Firebase Auth Setup
```javascript
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";

const auth = getAuth();

export const loginUser = async (email, password) => {
  const userCredential = await signInWithEmailAndPassword(auth, email, password);
  const idToken = await userCredential.user.getIdToken();

  // Sync with Backend
  await fetch("https://api.riyo.com/v1/users/sync", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${idToken}`,
    },
    body: JSON.stringify({
      firebase_id: userCredential.user.uid,
      email: userCredential.user.email,
    }),
  });

  return userCredential.user;
};
```

### 2. Axios Interceptor (Recommended)
```javascript
import axios from 'axios';
import { getAuth } from 'firebase/auth';

const api = axios.create({
  baseURL: 'https://api.riyo.com/v1',
});

api.interceptors.request.use(async (config) => {
  const auth = getAuth();
  const user = auth.currentUser;
  if (user) {
    const token = await user.getIdToken();
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Logic for logout or re-authentication
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

---

## 🔐 Security Best Practices

1. **Short-lived Tokens:** Firebase ID Tokens expire every hour. Always use `getIdToken()` (Flutter) or `getIdToken(true)` (React) before making a request to ensure you have a fresh token.
2. **Account Suspension:** If the backend returns a `401` or a specific error code indicating suspension, immediately clear local state and force logout.
3. **HTTPS:** Ensure the API Gateway is only accessible via HTTPS in production.
