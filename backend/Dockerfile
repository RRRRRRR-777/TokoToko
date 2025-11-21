# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a \
    -o /app/bin/api \
    ./cmd/api

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy CA certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /app/bin/api /api

# Run as non-root user (already set by distroless:nonroot)
USER nonroot:nonroot

# Expose port
EXPOSE 8080

# Run application
# Note: Health checks are handled by Kubernetes liveness/readiness probes
# See: deploy/kubernetes/base/deployment.yaml
ENTRYPOINT ["/api"]
