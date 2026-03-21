# RIYO Admin Setup Guide

## Default Admin Credentials

Upon initial startup, the system automatically creates a default admin account:

- **Username**: `sahan`
- **Password**: `sahan00`
- **Email**: `aabahatechnologyada@gmail.com`

> **IMPORTANT**: It is highly recommended to change these credentials immediately after your first login via the **Settings** page in the Admin Control Center.

## Security Best Practices

1. **Change Default Credentials**: As mentioned above, always update the default username and password.
2. **Enable Two-Factor Authentication (2FA)**: Use the built-in 2FA setup in the Settings page to link your account with Google Authenticator.
3. **Environment Secrets**: Ensure your `JWT_SECRET` is long, random, and never shared.
4. **Firebase SDK**: Keep your `firebase-credentials.json` file out of public repositories.
5. **Session Management**: JWT tokens are issued with a 1-hour expiration by default. The "Remember me" option extends this for convenient yet persistent access on trusted devices.
6. **Account Lockout**: The system will automatically lock an account for 15 minutes after 5 consecutive failed login attempts to prevent brute-force attacks.

## Initializing in MongoDB

The initialization logic is located in `backend/internal/db/db.go`. If you need to manually re-seed the admin:

1. Ensure the `users` collection in the `riyo` database is empty or does not contain a user with the email `aabahatechnologyada@gmail.com`.
2. Restart the backend service.
3. The `createDefaultAdmin()` function will run automatically on startup.
