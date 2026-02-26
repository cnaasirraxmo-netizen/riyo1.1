# Enterprise Microservices Architecture: RIYO Platform

This document outlines the production-ready microservices architecture for the RIYO streaming platform, focusing on the User Management system, scalability, and security.

---

## 🎯 Part 1: Overall System Architecture

### 1. Architecture Overview
The system follows a **Cloud-Native Microservices Architecture**. It decouples authentication, user management, content delivery, and subscriptions into independent services.

### 2. High-Level Diagram (Text-Based)
```text
[ Clients ]
    ├── Flutter Mobile App (Android)
    ├── React Web User App
    └── React Admin Dashboard
           │
           ▼
[ API Gateway (Go) ] <───> [ Firebase Auth (Identity Provider) ]
    │   (Routing, Rate Limiting, Auth Verification, Token Forwarding)
    │
    ├───▶ [ User Service (Go) ] ◀───▶ [ PostgreSQL ]
    │       (User CRUD, RBAC, Account Status)
    │
    ├───▶ [ Subscription Service (Go) ] ◀───▶ [ PostgreSQL ]
    │       (Plans, Billing, Expiration)
    │
    └───▶ [ Content Service (Go) ] ◀───▶ [ MongoDB ]
            (Movies, Watch History, Favorites)

[ Shared Infrastructure ]
    ├── Redis (Caching & Rate Limiting)
    ├── RabbitMQ/Kafka (Event-Driven Communication - Optional)
    └── Docker & Kubernetes (Orchestration)
```

### 3. Key Architectural Decisions
- **Firebase Authentication:** Handles the complexity of social logins (Google, Facebook) and email/password securely.
- **Go (Golang):** Chosen for its high concurrency, low memory footprint, and fast execution—ideal for microservices.
- **API Gateway:** Acts as the single entry point, offloading authentication verification from internal services.
- **Internal JWT:** The Gateway verifies the Firebase token and generates a short-lived internal JWT (using `RS256` or `HS256`) containing the `UID` and `Role`. Downstream services verify this token to ensure the request originated from the Gateway.

---

## 🎯 Part 2: Services Breakdown

### 1️⃣ API Gateway
- **Entry Point:** Single endpoint (`api.riyo.com`) for all clients.
- **Routing:** Directs traffic based on URL patterns (e.g., `/v1/users/**` -> User Service).
- **Public vs Private:** Routes are categorized. Public routes (e.g., `/v1/content/trending`) bypass auth; Private routes require a valid Firebase ID Token.
- **Token Forwarding:** Extracts `X-User-ID` and `X-User-Role` after verification and injects them into headers for downstream services.

### 2️⃣ User Service (Go)
- **User CRUD:** Manages profile data.
- **Role Management:** Handles `User` and `Admin` roles.
- **Account Status:** `active`, `suspended`, `pending_verification`.
- **Firebase Sync:** Automatically creates a database record upon the first login via Firebase.

### 3️⃣ Subscription Service (Go)
- **Logic:** Validates if a user has an active plan before allowing access to premium content.
- **State:** Tracks plan IDs, start/end dates, and renewal status.

### 4️⃣ Content / Watch Service (Go)
- **Watch History:** High-write operations, ideal for optimized storage.
- **Favorites:** "My List" functionality.

### 5️⃣ Admin Service (Internal)
- **Role-Based Access:** Only accessible by users with the `Admin` role.
- **Capabilities:** Global user search, suspension, and system statistics.

---

## 🎯 Part 3: Authentication Flow

### Mobile/Web Login Flow
1. **Firebase Login:** The client (Flutter/React) authenticates directly with Firebase SDK.
2. **ID Token Generation:** Firebase returns a short-lived **ID Token**.
3. **API Request:** Client sends the ID Token in the `Authorization: Bearer <ID_TOKEN>` header to the API Gateway.
4. **Gateway Verification:**
   - Gateway verifies the token against Firebase Admin SDK.
   - Gateway checks if the user is suspended via a quick Redis lookup.
5. **Context Injection:** Gateway forwards the request to the User Service with internal headers (`X-User-ID`, `X-User-Role`).
6. **User Sync:** If the User Service doesn't find the ID in its database, it creates a new record (Just-In-Time Provisioning).
7. **Response:** A standardized JSON response is returned.

---

## 🎯 Part 4: Database Design

### Why PostgreSQL?
We choose **PostgreSQL** for the User and Subscription services because:
- **ACID Compliance:** Essential for handling user accounts and financial subscription data.
- **Relational Integrity:** Strong typing and foreign keys prevent orphaned data (e.g., a subscription without a user).
- **JSONB Support:** Offers flexibility if we need to store semi-structured metadata while maintaining relational benefits.

### Core Tables
- **users:** `id (UUID)`, `firebase_id (String, Indexed)`, `email`, `name`, `role_id`, `status`, `created_at`.
- **roles:** `id`, `name` (Admin, User).
- **subscriptions:** `id`, `user_id`, `plan_type`, `expires_at`, `is_active`.
- **watch_history:** `id`, `user_id`, `content_id`, `progress`, `updated_at`.

---

## 🎯 Part 5: Go Clean Architecture

Each service follows this structure:
```text
/cmd
  /api          # Entry point (main.go)
/internal
  /domain       # Entities and Interfaces (Business Logic)
  /usecase      # Business Logic implementation (Service Layer)
  /repository   # Data access (Postgres, Redis)
  /delivery     # Transport layer (HTTP Handlers)
  /middleware   # Auth, Logging, Recovery
/pkg
  /config       # Configuration loader
  /firebase     # Firebase Admin SDK wrapper
  /utils        # Standardized response helpers
```

---

## 🎯 Part 6: Security & Scalability

### Security
- **Firebase Admin SDK:** Server-side verification of all incoming tokens.
- **Internal JWT:** All internal service-to-service calls require an `X-Internal-Token` header. The Gateway generates this token after verifying the Firebase ID Token. Downstream services use an `InternalAuthMiddleware` to validate it.
- **Rate Limiting:** Implemented at the Gateway level using a sliding window algorithm in Redis.
- **Statelessness:** Services do not store session state; all info is in the token or database.

### Scalability
- **Horizontal Scaling:** All services are stateless and can be scaled to N instances behind a Load Balancer.
- **Redis Caching:** Frequently accessed data (User Roles, Subscription Status) is cached in Redis with a TTL.
- **Database Indexing:** B-Tree indexes on `firebase_id` and `email` for O(1) lookups.

---

## 🎯 Part 7: Standard API Response Format

All services return a unified JSON structure:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "error": null
}
```
**Error Handling:**
- 400: Bad Request (Validation errors)
- 401: Unauthorized (Invalid Firebase token)
- 403: Forbidden (Admin role required)
- 404: Not Found
- 500: Internal Server Error

---

## 🎯 Part 8: Flutter & React Integration

- **Secure Storage:**
  - Flutter: `flutter_secure_storage` for the ID Token.
  - React: HttpOnly Cookies (if same-domain) or secure Memory state with Refresh logic.
- **Interceptor Pattern:**
  - Every outgoing request automatically attaches the `Authorization` header.
  - On `401 Unauthorized`, the client attempts to refresh the Firebase token. If refresh fails, the user is logged out.
- **Auto-Logout:** If the `account_status` in any response is `suspended`, the app clears local storage and redirects to the login screen.

---

## 🎯 Part 9: Production Deployment

### 1. Dockerization
Each service has a multi-stage `Dockerfile` (Build in Go, Run in Alpine).

### 2. CI/CD Pipeline
- **Linting & Testing:** Run on every Pull Request.
- **Build:** Create Docker images and push to a Registry (GCR/ECR).
- **Deploy:** Rolling updates to Kubernetes or a managed service like AWS App Runner / Google Cloud Run.

### 3. Monitoring
- **Logging:** Structured JSON logs (Zap/Logrus) sent to ELK Stack or Datadog.
- **Metrics:** Prometheus metrics for latency and error rates.
