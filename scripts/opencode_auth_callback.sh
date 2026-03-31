#!/bin/bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
OPENCODE_WRAPPER="${REPO_DIR}/opencode/.local/bin/opencode"

if [[ ! -x "$OPENCODE_WRAPPER" ]]; then
    echo "Error: opencode wrapper not found at '$OPENCODE_WRAPPER'." >&2
    exit 1
fi

exec "$OPENCODE_WRAPPER" callback "$@"
