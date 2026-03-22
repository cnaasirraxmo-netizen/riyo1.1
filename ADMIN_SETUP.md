# Riyo Secure Admin System Setup

This document provides instructions for setting up and maintaining the secure admin system for the Riyo platform.

## 1. Initial Admin Credentials
When the system initializes for the first time, it automatically creates a default admin account in MongoDB:

- **Username**: `sahan`
- **Password**: `sahan00`
- **Email**: `aabahatechnologyada@gmail.com`

**Action Required**: Immediately log in and change these credentials from the **Settings** page in the Admin Dashboard.

## 2. Security Features

### Authentication & Authorization
- **JWT (JSON Web Tokens)**: Secure tokens used for all authenticated requests.
  - Default expiration: **1 hour**.
  - Extended expiration (with "Remember Me"): **30 days**.
- **Role-Based Access Control (RBAC)**: Only users with the `admin` role can access `/admin/*` and `/upload/*` routes.
- **Password Hashing**: All passwords are encrypted using `bcrypt` (10 rounds).

### Brute-Force & Bot Protection
- **Account Lockout**: After **5 failed login attempts**, the account is automatically locked for **15 minutes**.
- **API Rate Limiting**: The authentication API (`/auth/login`, `/auth/forgot-password`, etc.) is limited to **5 requests per minute per IP**.

### Two-Factor Authentication (2FA)
- Admins can enable **Google Authenticator** (TOTP) from the Settings page.
- Once enabled, a 6-digit code will be required for every login.

## 3. Password Reset Flow
The system uses a secure 6-digit code-based reset flow:
1. Admin requests a reset via the "Forgot Password" link.
2. A random code is generated and saved in MongoDB (valid for 15 minutes).
3. The code is sent to the admin's email.
4. Admin enters the code and their new password in the dashboard.
5. The password is hashed and updated in MongoDB.

## 4. Backend Configuration (.env)

```env
JWT_SECRET=your_jwt_secret
MONGO_URI=your_mongodb_uri
SENDGRID_API_KEY=your_sendgrid_key # or SMTP credentials
FIREBASE_CREDENTIALS_FILE=firebase.json
```

## 5. Security Best Practices for Production
1. **Always use HTTPS**: Ensure the backend and frontend are served over TLS.
2. **Set JWT_SECRET**: Use a long, random string.
3. **Configure CORS**: Limit `AllowOrigins` to your specific domain.
4. **Regular Audits**: Monitor the `users` collection for unusual `loginAttempts` or `lockedUntil` timestamps.
