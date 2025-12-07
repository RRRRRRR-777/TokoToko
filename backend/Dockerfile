# Build stage
ARG GO_VERSION=1.24
FROM golang:${GO_VERSION}-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata curl

# Download golang-migrate CLI
RUN curl -L https://github.com/golang-migrate/migrate/releases/download/v4.17.0/migrate.linux-amd64.tar.gz | tar xvz \
    && mv migrate /usr/local/bin/migrate

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

# Copy migrate CLI
COPY --from=builder /usr/local/bin/migrate /migrate

# Copy migrations
COPY --from=builder /app/migrations /app/migrations

# Run as non-root user (already set by distroless:nonroot)
USER nonroot:nonroot

# Expose port
EXPOSE 8080

# Run application
# Note: Health checks are handled by Kubernetes liveness/readiness probes
# See: deploy/kubernetes/base/deployment.yaml
ENTRYPOINT ["/api"]
