# Stage 1: Build
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy the workspace and modules
COPY go.work ./
COPY pkg/ ./pkg/
COPY api-gateway/ ./api-gateway/

# Build the application
WORKDIR /app/api-gateway
RUN go build -o main ./cmd/api/main.go

# Stage 2: Run
FROM alpine:latest

WORKDIR /root/
COPY --from=builder /app/api-gateway/main .

EXPOSE 8080

CMD ["./main"]
