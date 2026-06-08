FROM golang:1.25.11-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o muchtodo-backend ./cmd/api/main.go

FROM alpine:3.20

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN apk add --no-cache ca-certificates curl

WORKDIR /app

COPY --from=builder /app/muchtodo-backend /usr/local/bin/muchtodo-backend

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["/usr/local/bin/muchtodo-backend"]
