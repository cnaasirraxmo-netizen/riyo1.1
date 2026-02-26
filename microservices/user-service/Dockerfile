# Stage 1: Build
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy the workspace and modules
COPY go.work ./
COPY pkg/ ./pkg/
COPY user-service/ ./user-service/

# Build the application
WORKDIR /app/user-service
RUN go build -o main ./cmd/api/main.go

# Stage 2: Run
FROM alpine:latest

WORKDIR /root/
COPY --from=builder /app/user-service/main .

EXPOSE 8081

CMD ["./main"]
