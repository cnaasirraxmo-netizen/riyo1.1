# Performance Audit: RIYO Platform

This document outlines the findings of the performance audit conducted on the RIYO platform (Node.js, MongoDB, React, Flutter).

## 1. Backend (Node.js) Findings

### Critical: Event Loop Blocking
- **Issue**: Large file uploads (up to 1GB) were handled using `multer.memoryStorage()`.
- **Impact**: Loading a 1GB file into RAM blocks the Node.js event loop during the buffer allocation and processing. Multiple concurrent uploads would lead to Out-Of-Memory (OOM) crashes and high latency for all users.
- **Status**: Identified. Switching to Signed URLs for direct client-to-storage uploads is recommended.

### Missing Optimization Middleware
- **Issue**: No response compression or security headers.
- **Impact**: Large JSON payloads for movie lists were sent uncompressed, increasing bandwidth usage and load times. Lack of security headers (Helmet) exposes the app to common web vulnerabilities.
- **Status**: **FIXED**. Added `compression` and `helmet` middleware.

### Lack of Rate Limiting
- **Issue**: Auth routes had no protection against brute-force attacks.
- **Impact**: Risk of account hijacking and server resource exhaustion.
- **Status**: **FIXED**. Implemented `express-rate-limit` on auth routes.

---

## 2. Database (MongoDB) Findings

### Critical: Collection Scans (Missing Indexes)
- **Issue**: No indexes on frequently queried fields like `genre`, `isTrending`, `isFeatured`, `contentType`, and `isPublished`.
- **Impact**: MongoDB performs a full collection scan for every home screen row and category filter. Performance degrades linearly with the number of movies.
- **Status**: **FIXED**. Added B-Tree indexes to all query fields in the `Movie` model.

### Missing Pagination
- **Issue**: The `/movies` and `/admin/movies` endpoints returned all documents at once.
- **Impact**: As the database grows, API response times and payload sizes increase significantly, eventually causing browser/app timeouts.
- **Status**: **FIXED**. Implemented `skip`/`limit` pagination on the server side.

---

## 3. API Findings

### Response Size
- **Issue**: Fetching all movies resulted in massive JSON payloads.
- **Impact**: Slow initial load for users on mobile or slow connections.
- **Status**: **FIXED**. Paginated responses now return metadata (`page`, `total`, `pages`) and limited document counts.

### Search Efficiency
- **Issue**: Search was performed by fetching *all* movies and filtering them on the frontend.
- **Impact**: Extremely slow search experience once the library exceeds a few dozen titles.
- **Status**: **FIXED**. Implemented server-side regex search.

---

## 4. Frontend Findings

### Bundle Size
- **Issue**: No code splitting in the React applications.
- **Impact**: Users had to download the entire application code (Login, Admin, Player, etc.) before the first meaningful paint.
- **Status**: **FIXED**. Implemented `React.lazy` and `Suspense` for route-based code splitting.

### Unnecessary Re-renders
- **Issue**: State management for movie lists wasn't optimized.
- **Impact**: Laggy UI when scrolling through many rows.
- **Status**: Recommendations provided in `OPTIMIZATION.md`.

---

## 5. Cloud Storage (R2) Findings

### Thread Blocking
- **Issue**: The backend acted as a proxy for file uploads.
- **Impact**: Node.js is not optimized for handling heavy binary streams. This consumes CPU and memory that should be used for handling API logic.
- **Status**: Optimization strategy for Client-Side direct uploads documented.
