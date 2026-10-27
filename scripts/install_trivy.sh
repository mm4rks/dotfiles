#!/bin/bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck source=lib.sh
source "${REPO_DIR}/lib.sh"

TRIVY_VERSION="0.62.0"
# Pinned by digest as well: tags on Docker Hub are mutable.
TRIVY_DIGEST="sha256:cb84170aa1fb6942c11b638969dce0845735c35f40d3bd48851c7f2d83a3c1ae"
TRIVY_IMAGE="aquasec/trivy:${TRIVY_VERSION}@${TRIVY_DIGEST}"
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
    sudo docker pull "$TRIVY_IMAGE"

    log "Warming Trivy vulnerability databases..."
    mkdir -p "$CACHE_DIR"
    # Caches from older wrapper versions were written as root; the warm-up
    # below runs as the user and needs write access.
    sudo chown -R "$(id -u):$(id -g)" "$CACHE_DIR"
    sudo docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "${CACHE_DIR}:/trivy-cache" \
        "$TRIVY_IMAGE" \
        image --cache-dir=/trivy-cache --download-db-only
    sudo docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "${CACHE_DIR}:/trivy-cache" \
        "$TRIVY_IMAGE" \
        image --cache-dir=/trivy-cache --download-java-db-only

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
        --user "$(id -u):$(id -g)" \
        -v "${TRIVY_CACHE}:/trivy-cache" \
        "$TRIVY_IMAGE" image --cache-dir=/trivy-cache --download-db-only
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "${TRIVY_CACHE}:/trivy-cache" \
        "$TRIVY_IMAGE" image --cache-dir=/trivy-cache --download-java-db-only
    exit 0
fi

# Transparent path rewriting: for every arg that resolves to an existing
# path, mount its parent directory read-only at /scan_N and rewrite the arg.
# The -o/--output target is written to a private temp dir mounted read-write
# at /out and moved into place afterwards, so no existing host directory is
# ever writable from the container.
declare -A MOUNTED_DIRS
DOCKER_ARGS=()
TRIVY_ARGS=()
MOUNT_INDEX=0

# Usage: map_path <path>; sets MAPPED to the in-container path.
map_path() {
    local abs dir base
    abs=$(realpath -m "$1")
    dir=$(dirname "$abs")
    base=$(basename "$abs")
    if [[ -z "${MOUNTED_DIRS[$dir]+x}" ]]; then
        MOUNTED_DIRS["$dir"]="/scan_${MOUNT_INDEX}"
        DOCKER_ARGS+=("-v" "${dir}:/scan_${MOUNT_INDEX}:ro")
        (( MOUNT_INDEX++ )) || true
    fi
    MAPPED="${MOUNTED_DIRS[$dir]}/${base}"
}

OUT_DIR=""
OUTPUT_TARGET=""
# Usage: map_output <path>; sets MAPPED to the in-container report path.
map_output() {
    OUTPUT_TARGET=$(realpath -m "$1")
    if [[ ! -d "$(dirname "$OUTPUT_TARGET")" ]]; then
        echo "trivy wrapper: output directory $(dirname "$OUTPUT_TARGET") does not exist" >&2
        exit 1
    fi
    OUT_DIR=$(mktemp -d)
    DOCKER_ARGS+=("-v" "${OUT_DIR}:/out:rw")
    MAPPED="/out/report"
}

prev=""
for arg in "$@"; do
    if [[ "$prev" == "-o" || "$prev" == "--output" ]]; then
        map_output "$arg"
        TRIVY_ARGS+=("$MAPPED")
    elif [[ "$arg" == --output=* ]]; then
        map_output "${arg#--output=}"
        TRIVY_ARGS+=("--output=${MAPPED}")
    elif [[ -e "$arg" ]]; then
        map_path "$arg"
        TRIVY_ARGS+=("$MAPPED")
    else
        TRIVY_ARGS+=("$arg")
    fi
    prev="$arg"
done

# Run as the invoking user so reports written via -o are owned by them.
status=0
docker run --rm \
    --network none \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "${TRIVY_CACHE}:/trivy-cache" \
    "${DOCKER_ARGS[@]+"${DOCKER_ARGS[@]}"}" \
    "$TRIVY_IMAGE" \
    --cache-dir=/trivy-cache \
    --skip-db-update \
    --skip-java-db-update \
    "${TRIVY_ARGS[@]+"${TRIVY_ARGS[@]}"}" || status=$?

if [[ -n "$OUT_DIR" ]]; then
    if [[ -f "${OUT_DIR}/report" ]]; then
        mv "${OUT_DIR}/report" "$OUTPUT_TARGET"
    fi
    rm -rf "$OUT_DIR"
fi
exit "$status"
WRAPPER_EOF
    } > "$WRAPPER"

    chmod +x "$WRAPPER"
    log "Trivy ${TRIVY_VERSION} wrapper installed."
}

main "$@"
