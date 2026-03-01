#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="kiro-cli-dev"
CONTAINER_DATA_VOLUME="kiro-cli-data"
CONTAINER_CONFIG_VOLUME="kiro-cli-config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BUILD=false
PROMPT=""
SHELL_MODE=false
NO_FIREWALL=false
EXTRA_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --build)
            BUILD=true
            shift
            ;;
        -p|--prompt)
            PROMPT="$2"
            shift 2
            ;;
        --shell)
            SHELL_MODE=true
            shift
            ;;
        --no-firewall)
            NO_FIREWALL=true
            shift
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

# Build if image doesn't exist or --build flag passed
if [[ "$BUILD" == true ]] || ! podman image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building $IMAGE_NAME image..."
    podman build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

# Assemble podman run arguments
RUN_ARGS=(
    --rm
    -it
    -v "$(pwd):/workspace"
    -v "${CONTAINER_DATA_VOLUME}:/home/node/.local/share/kiro-cli"
    -v "${CONTAINER_CONFIG_VOLUME}:/home/node/.kiro"
    --cap-add=NET_ADMIN
    --cap-add=NET_RAW
    -e "NO_FIREWALL=${NO_FIREWALL}"
    -w /workspace
)

# Set command based on mode (entrypoint always runs firewall first)
if [[ "$SHELL_MODE" == true ]]; then
    RUN_ARGS+=("$IMAGE_NAME" /bin/bash)
elif [[ -n "$PROMPT" ]]; then
    RUN_ARGS+=("$IMAGE_NAME" kiro-cli chat -p "$PROMPT")
else
    RUN_ARGS+=("$IMAGE_NAME" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"})
fi

exec podman run "${RUN_ARGS[@]}"
