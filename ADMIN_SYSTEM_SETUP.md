# Secure Admin System Deployment & Initialization

## 🚀 Backend Initialization (Node.js)

1. **Environment Setup**:
   - Copy `backend_node/.env.example` to `backend_node/.env`.
   - Update `MONGO_URI` with your connection string.
   - Set a strong `JWT_SECRET`.
   - Provide your `firebase-credentials.json` for password reset functionality.

2. **Default Admin Account**:
   - On the first run, the system automatically creates the default admin user:
     - **Username**: `sahan`
     - **Password**: `sahan00`
     - **Email**: `aabahatechnologyada@gmail.com`
   - You can log in immediately with these credentials and update them via the **Settings** page.

3. **Security Best Practices Implemented**:
   - **Password Hashing**: Bcrypt with 12 rounds.
   - **Brute-Force Protection**: Account lockout after 5 failed attempts (15-minute cooldown).
   - **Hardening**: `Helmet` for secure HTTP headers, `CORS` configuration, and `express-rate-limit` for API throttling.
   - **JWT**: Stateless session management with configurable expiration (1h default, 30d for 'Remember Me').

## 💻 Frontend Setup (React)

1. **Firebase Config**:
   - Add your Firebase client configuration to `web_admin/.env`:
     - `VITE_FIREBASE_API_KEY`
     - `VITE_FIREBASE_AUTH_DOMAIN`
     - ... (see `web_admin/src/config/firebase.js`)

2. **API Communication**:
   - The frontend uses a centralized Axios instance in `src/utils/api.js`.
   - It automatically attaches the `Authorization: Bearer <token>` header.
   - It intercepts `401 Unauthorized` responses to redirect users to the login page.

## 🔐 Maintenance
- Periodically check server logs for brute-force attempts.
- Ensure the `JWT_SECRET` is rotated annually in high-security environments.
