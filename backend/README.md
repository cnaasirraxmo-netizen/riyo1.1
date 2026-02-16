# RIYOBOX Backend

Minimal Node.js backend for the RIYOBOX streaming app. It handles authentication, movie storage, and role-based access control.

## 🛠 Prerequisites

*   Node.js (v14 or higher)
*   MongoDB (Local installation or MongoDB Atlas)

## ⚙️ Local Setup

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Environment Configuration:**
    Create a `.env` file in the root of the `backend` folder. These variables are **required** for full functionality in deployment:
    ```env
    PORT=5000
    MONGO_URI=mongodb://localhost:27017/riyobox
    JWT_SECRET=your_super_secret_key

    # Cloudflare R2 Storage
    R2_ACCESS_KEY_ID=your_access_key
    R2_SECRET_ACCESS_KEY=your_secret_key
    R2_BUCKET_NAME=your_bucket_name
    R2_S3_ENDPOINT=https://your_account_id.r2.cloudflarestorage.com
    ```

4.  **Start the server:**
    ```bash
    # Normal start
    npm start

    # Development start (if nodemon is installed)
    npm run dev
    ```

## 🛡 Authentication & Roles

The system automatically creates a Super Admin on the first run.

*   **Email:** `admin@example.com`
*   **Password:** `admin123`

### Roles
*   `user`: Can view and stream movies.
*   `admin`: Can add, view, and delete movies via the Admin Panel.

## 📡 API Endpoints

### Auth
*   `POST /auth/register` (Public): Create a new user account.
*   `POST /auth/login` (Public): Authenticate and receive a JWT.

### Movies (User)
*   `GET /movies` (Private): List all available movies.
*   `GET /movies/:id` (Private): Get detailed info for a specific movie.

### Admin (Admin Only)
*   `GET /admin/movies`: List all movies with backend IDs.
*   `POST /admin/movies`: Upload movie info and an external video link.
*   `DELETE /admin/movies/:id`: Remove a movie from the database.

## 📝 Important Notes
*   **Video Links:** The Admin Panel accepts direct video links (e.g., `.mp4`, `.m3u8`). Ensure links are accessible by the client app.
*   **Cross-Origin:** CORS is enabled to allow the Flutter app to communicate with the server during development.
