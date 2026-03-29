#!/bin/bash
set -euo pipefail

# This script helps complete the OpenCode OAuth flow when running in a Docker sandbox.
# 1. Run 'opencode providers login google' in Terminal A.
# 2. Authenticate in your browser.
# 3. Copy the 'localhost' URL the browser tries to redirect to.
# 4. Run this script with that URL: ./scripts/opencode_auth_callback.sh "http://localhost:8085/..."

URL="${1:-}"

if [[ -z "$URL" ]]; then
    echo "Usage: $0 <callback_url>"
    exit 1
fi

CONTAINER_NAME="opencode-sandbox-$(id -u)"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: opencode sandbox is not currently running."
    echo "Please start the login process in another terminal first."
    exit 1
fi

echo "Sending callback to sandbox container..."
docker exec "$CONTAINER_NAME" curl -sL "$URL"
echo "Done. Check your opencode terminal for the result."
