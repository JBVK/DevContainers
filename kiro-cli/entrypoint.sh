#!/usr/bin/env bash
set -euo pipefail

# Check login status before firewall is up (needs unrestricted network)
NEEDS_LOGIN=false
if [[ "${1:-}" != "/bin/bash" ]]; then
    if ! timeout 10 kiro-cli whoami &>/dev/null; then
        NEEDS_LOGIN=true
    fi
fi

# If not logged in, do device-flow login before firewall locks things down
if [[ "$NEEDS_LOGIN" == true ]]; then
    echo "Not logged in. Starting device-flow login..."
    echo "You will see a URL and code — open the URL in your browser and enter the code."
    echo ""
    kiro-cli login --use-device-flow
fi

# Initialize firewall (runs as root via sudo)
if [[ "${NO_FIREWALL:-false}" == "true" ]]; then
    echo "Firewall disabled via --no-firewall flag." >&2
elif ! sudo /usr/local/bin/init-firewall.sh 2>/dev/null; then
    echo "WARNING: Firewall init failed (missing NET_ADMIN capability?). Running without network restrictions." >&2
fi

# Execute the requested command (default: kiro-cli chat)
exec "$@"
