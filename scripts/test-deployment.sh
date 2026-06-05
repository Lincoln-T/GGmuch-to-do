#!/usr/bin/env bash
set -euo pipefail

FRONTEND_URL="${1:-}"
BACKEND_API_URL="${2:-}"

if [ -z "$FRONTEND_URL" ] || [ -z "$BACKEND_API_URL" ]; then
  echo "Usage: ./scripts/test-deployment.sh <frontend_url> <backend_api_url>"
  echo "Example:"
  echo "./scripts/test-deployment.sh https://example.cloudfront.net https://example.cloudfront.net/api"
  exit 1
fi

echo "Testing frontend..."
curl -I "${FRONTEND_URL}"

echo ""
echo "Testing backend root endpoint..."
curl -i "${BACKEND_API_URL}/"

echo ""
echo "Testing backend ping endpoint..."
curl -i "${BACKEND_API_URL}/ping"

echo ""
echo "Deployment test completed."
