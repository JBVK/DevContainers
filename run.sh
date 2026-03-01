#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="claude-code-dev"
CONTAINER_CONFIG_VOLUME="claude-code-config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BUILD=false
PROMPT=""
SHELL_MODE=false
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

# Assemble docker run arguments
RUN_ARGS=(
    --rm
    -it
    -v "$(pwd):/workspace"
    -v "${CONTAINER_CONFIG_VOLUME}:/home/node/.claude"
    --cap-add=NET_ADMIN
    --cap-add=NET_RAW
    -w /workspace
)

# Set command based on mode (entrypoint always runs firewall first)
if [[ "$SHELL_MODE" == true ]]; then
    RUN_ARGS+=("$IMAGE_NAME" /bin/bash)
elif [[ -n "$PROMPT" ]]; then
    RUN_ARGS+=("$IMAGE_NAME" claude --dangerously-skip-permissions -p "$PROMPT")
else
    RUN_ARGS+=("$IMAGE_NAME" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"})
fi

exec podman run "${RUN_ARGS[@]}"
