# Firebase Authentication Backend Setup

This document explains how to set up Firebase Authentication for the Go backend.

## Overview

The backend uses the Firebase Admin SDK to verify ID tokens sent from the frontend (Web or Mobile). This ensures that only authenticated users can access protected resources.

## Steps to Setup

### 1. Obtain Firebase Service Account Credentials

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Navigate to **Project Settings** > **Service accounts**.
3. Click **Generate new private key**.
4. Save the downloaded JSON file as `firebase-credentials.json` in the `backend/` directory.

### 2. Environment Variable

The backend expects an environment variable `FIREBASE_CREDENTIALS_FILE` pointing to the path of the JSON credentials file.

- **Local Development**: Add `FIREBASE_CREDENTIALS_FILE=firebase-credentials.json` to your `.env` file.
- **Docker**: The `Dockerfile` is already configured to copy this file and set the environment variable.

### 3. Verification Endpoint

The backend provides a `/auth/verify` endpoint to validate Firebase ID tokens.

- **URL**: `/auth/verify`
- **Method**: `POST`
- **Request Body**:
  ```json
  {
    "idToken": "FIREBASE_ID_TOKEN_HERE"
  }
  ```
- **Success Response**:
  ```json
  {
    "uid": "USER_UID",
    "email": "user@example.com",
    "name": "User Name"
  }
  ```

## Security Note

Never commit `firebase-credentials.json` to version control. It is added to `.gitignore` by default (if not, please add it). Use `firebase-credentials.json.example` as a template.
