# RIYOBOX Go Backend

This is the Go rewrite of the RIYOBOX backend, using Gin and MongoDB.

## Features

- JWT Authentication with "Admin Bypass" logic
- MongoDB for data persistence
- Cloudflare R2 for media storage
- Deployment-ready with Docker

## Getting Started

1. Set up your environment variables in a `.env` file:
   ```
   MONGO_URI=mongodb://localhost:27017/riyo
   JWT_SECRET=your_jwt_secret
   R2_ACCESS_KEY_ID=your_r2_access_key
   R2_SECRET_ACCESS_KEY=your_r2_secret_key
   R2_BUCKET_NAME=your_r2_bucket
   R2_S3_ENDPOINT=https://your_account_id.r2.cloudflarestorage.com
   ```

2. Run with Go:
   ```bash
   go run cmd/api/main.go
   ```

3. Run with Docker:
   ```bash
   docker build -t riyobox-backend-go .
   docker run -p 5000:5000 riyobox-backend-go
   ```

## Deployment on Render

To deploy this backend on [Render](https://render.com), follow these steps:

1. **Create a New Web Service**: Select "Web Service" from your Render dashboard and connect your repository.
2. **Specify Root Directory**: Set the root directory to `backend`.
3. **Select Runtime**: Choose "Docker".
4. **Configure Environment Variables**: Add all required variables in the Render "Env" tab:
   - `MONGO_URI`
   - `JWT_SECRET`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`
   - `R2_BUCKET_NAME`
   - `R2_S3_ENDPOINT`
5. **Wait for Build**: Render will automatically detect the `Dockerfile` and build/deploy your service.

## Differences from Node.js Version

- Faster execution and lower memory footprint.
- Built-in type safety with Go structs.
- Unified response structures.
