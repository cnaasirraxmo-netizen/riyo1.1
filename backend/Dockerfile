# Stage 1: Build Go app
FROM golang:1.26-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o main ./cmd/api

# Stage 2: Runtime
FROM alpine:latest

# Install dependencies + Chromium
RUN apk add --no-cache \
    ffmpeg \
    ca-certificates \
    chromium \
    nss \
    harfbuzz \
    ttf-freefont \
    bash \
    fontconfig

WORKDIR /app

COPY --from=builder /app/main .
COPY .env* ./
COPY firebase-credentials.json* ./

# Environment variables for Rod + Firebase
ENV FIREBASE_CREDENTIALS_FILE=/app/firebase-credentials.json
ENV ROD_SKIP_BROWSER_DOWNLOAD=true
ENV CHROME_PATH=/usr/bin/chromium-browser

EXPOSE 5000

CMD ["./main"]
