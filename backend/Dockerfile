FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o main ./cmd/api

FROM alpine:latest

# Install FFmpeg and dependencies
RUN apk add --no-cache ffmpeg ca-certificates

WORKDIR /app

COPY --from=builder /app/main .
COPY .env* ./
COPY firebase-credentials.json* ./

# Set environment variable for Firebase credentials
ENV FIREBASE_CREDENTIALS_FILE=/app/firebase-credentials.json

EXPOSE 5000

CMD ["./main"]
