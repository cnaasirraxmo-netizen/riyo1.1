# Cloudflare R2 Storage Setup Guide

This guide explains how to configure Cloudflare R2 for use with the RIYO backend.

## 1. Create a Bucket
1. Log in to your Cloudflare Dashboard.
2. Go to **R2** in the sidebar.
3. Click **Create bucket**.
4. Name your bucket (e.g., `riyo-content`).

## 2. Configure Public Access
To allow the app to play videos and show posters, you need to enable public access:
1. Inside your bucket, go to the **Settings** tab.
2. Under **Public Access**, click **Connect Domain** or enable **R2.dev subdomain**.
3. If using `R2.dev`, note that it's meant for testing and might have rate limits. For production, connect a custom domain.

## 3. Configure CORS
CORS (Cross-Origin Resource Sharing) must be configured to allow the Web Admin and Mobile app to upload files directly.
1. Go to the **Settings** tab of your bucket.
2. Scroll down to **CORS Policy**.
3. Click **Add CORS Policy**.
4. Paste the following JSON:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
    "AllowedHeaders": ["Content-Type", "Authorization"],
    "ExposeHeaders": [],
    "MaxAgeSeconds": 3000
  }
]
```
*Note: In production, replace `"*"` with your actual Web Admin URL (e.g., `https://riyo-admin.vercel.app`).*

## 4. Get API Credentials
1. Go to the **R2** overview page.
2. Click **Manage R2 API Tokens** on the right side.
3. Click **Create API token**.
4. Permissions: Select **Admin Read & Write**.
5. Copy the following values to your `.env` file on Render/local:
   - `R2_ACCESS_KEY_ID`: Your Access Key ID.
   - `R2_SECRET_ACCESS_KEY`: Your Secret Access Key.
- `R2_ACCOUNT_ID`: Your Cloudflare Account ID (found on R2 overview).
- `R2_S3_ENDPOINT`: (Optional) If not provided, it will be constructed using `R2_ACCOUNT_ID`.
   - `R2_BUCKET_NAME`: The name you gave your bucket.
- `R2_PUBLIC_URL`: (Recommended) Your custom domain or R2.dev subdomain (e.g., `https://pub-xxx.r2.dev`).

## 5. Public URL Note
For videos to play in the app and browser, you **MUST** enable **Public Access** in the R2 dashboard:
1. Bucket -> Settings -> Public Access.
2. Enable `R2.dev subdomain` or **Connect Domain** (Recommended).
3. Copy this URL and set it as `R2_PUBLIC_URL` in your environment.

## 6. Summary of Environment Variables
```env
R2_ACCOUNT_ID=c81ae2ecbace64405fb7d62cf5ae8a5f
R2_ACCESS_KEY_ID=your_access_key
R2_SECRET_ACCESS_KEY=your_secret_key
R2_BUCKET_NAME=riyo-content
R2_PUBLIC_URL=https://your-custom-domain.com
```
