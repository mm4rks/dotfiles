#!/bin/bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck source=lib.sh
source "${REPO_DIR}/lib.sh"

TRIVY_VERSION="0.62.0"
TRIVY_IMAGE="aquasec/trivy:${TRIVY_VERSION}"
CACHE_DIR="${HOME}/.cache/trivy"
WRAPPER="${HOME}/.local/bin/trivy"

main() {
    if ! command_exists docker; then
        error "Docker is required for the hardened Trivy wrapper but was not found."
    fi

    if [[ -x "$WRAPPER" ]] && grep -q "TRIVY_IMAGE=\"${TRIVY_IMAGE}\"" "$WRAPPER" 2>/dev/null; then
        log "Trivy wrapper ${TRIVY_VERSION} already installed, skipping."
        return 0
    fi

    log "Pulling Trivy image ${TRIVY_IMAGE}..."
    docker pull "$TRIVY_IMAGE"

    log "Warming Trivy vulnerability databases..."
    mkdir -p "$CACHE_DIR"
    docker run --rm \
        -v "${CACHE_DIR}:/root/.cache/trivy" \
        "$TRIVY_IMAGE" \
        image --download-db-only
    docker run --rm \
        -v "${CACHE_DIR}:/root/.cache/trivy" \
        "$TRIVY_IMAGE" \
        image --download-java-db-only

    log "Installing Trivy wrapper to ${WRAPPER}..."
    mkdir -p "$(dirname "$WRAPPER")"

    # Emit the pinned image name as a variable, then append the static wrapper body.
    {
        printf '#!/bin/bash\nset -euo pipefail\n'
        printf 'TRIVY_IMAGE="%s"\n' "$TRIVY_IMAGE"
        printf 'TRIVY_CACHE="%s"\n' "$CACHE_DIR"
        cat << 'WRAPPER_EOF'

# --update-db: refresh vuln DBs with network access, then exit.
if [[ "${1:-}" == "--update-db" ]]; then
    docker run --rm \
        -v "${TRIVY_CACHE}:/root/.cache/trivy" \
        "$TRIVY_IMAGE" image --download-db-only
    docker run --rm \
        -v "${TRIVY_CACHE}:/root/.cache/trivy" \
        "$TRIVY_IMAGE" image --download-java-db-only
    exit 0
fi

# Transparent path rewriting: for every arg that resolves to an existing
# path, mount its parent directory read-only at /scan_N and rewrite the arg.
declare -A MOUNTED_DIRS
DOCKER_ARGS=()
TRIVY_ARGS=()
MOUNT_INDEX=0

for arg in "$@"; do
    if [[ -e "$arg" ]]; then
        abs=$(realpath "$arg")
        dir=$(dirname "$abs")
        base=$(basename "$abs")
        if [[ -z "${MOUNTED_DIRS[$dir]+x}" ]]; then
            mount_point="/scan_${MOUNT_INDEX}"
            MOUNTED_DIRS["$dir"]="$mount_point"
            DOCKER_ARGS+=("-v" "${dir}:${mount_point}:ro")
            (( MOUNT_INDEX++ )) || true
        fi
        TRIVY_ARGS+=("${MOUNTED_DIRS[$dir]}/${base}")
    else
        TRIVY_ARGS+=("$arg")
    fi
done

exec docker run --rm \
    --network none \
    -v "${TRIVY_CACHE}:/root/.cache/trivy" \
    "${DOCKER_ARGS[@]+"${DOCKER_ARGS[@]}"}" \
    "$TRIVY_IMAGE" \
    --skip-db-update \
    --skip-java-db-update \
    "${TRIVY_ARGS[@]+"${TRIVY_ARGS[@]}"}"
WRAPPER_EOF
    } > "$WRAPPER"

    chmod +x "$WRAPPER"
    log "Trivy ${TRIVY_VERSION} wrapper installed."
}

main "$@"
