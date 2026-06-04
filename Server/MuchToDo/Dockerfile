# syntax=docker/dockerfile:1.7

FROM golang:1.25-alpine AS builder

WORKDIR /src

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/much-to-do \
    ./cmd/api/main.go

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /out/much-to-do /app/much-to-do
COPY --from=builder /src/docs /app/docs

ENV PORT=8080 \
    GIN_MODE=release \
    ENABLE_CACHE=false \
    LOG_LEVEL=INFO \
    LOG_FORMAT=json

EXPOSE 8080

USER appuser

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -qO- "http://127.0.0.1:${PORT}/health" >/dev/null || exit 1

ENTRYPOINT ["/app/much-to-do"]
