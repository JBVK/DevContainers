#!/usr/bin/env bash
set -euo pipefail

# Firewall initialization script for kiro-cli dev container.
# Whitelists all AWS IP ranges plus common dev registries, blocks everything else.
# Must be run as root (via sudo).

ALLOWED_DOMAINS=(
    # Kiro core
    kiro.dev
    cli.kiro.dev
    api.kiro.dev
    auth.kiro.dev
    prod.us-east-1.auth.desktop.kiro.dev
    prod.us-east-1.telemetry.desktop.kiro.dev
    aws.dev
    awsstatic.com

    # npm
    registry.npmjs.org
    npmjs.com
    www.npmjs.com

    # GitHub
    github.com
    api.github.com
    raw.githubusercontent.com
    objects.githubusercontent.com

    # PyPI
    pypi.org
    files.pythonhosted.org

    # Go
    proxy.golang.org
    sum.golang.org
    storage.googleapis.com

    # uv / uvx (Python package manager for MCP servers)
    astral.sh
    github.com/astral-sh

    # General
    dl.google.com
    registry-1.docker.io
    auth.docker.io
    production.cloudflare.docker.com
)

# Create or flush the ipset (use maxelem to handle AWS's large IP list)
ipset create allowed_ips hash:net maxelem 131072 -exist
ipset flush allowed_ips

# Add all AWS IP ranges (official source)
echo "Fetching AWS IP ranges..."
AWS_RANGES=$(curl -fsSL https://ip-ranges.amazonaws.com/ip-ranges.json 2>/dev/null || true)
if [[ -n "$AWS_RANGES" ]]; then
    echo "$AWS_RANGES" | jq -r '.prefixes[].ip_prefix' 2>/dev/null | while read -r cidr; do
        ipset add allowed_ips "$cidr" -exist 2>/dev/null || true
    done
    echo "AWS IP ranges loaded."
else
    echo "WARNING: Could not fetch AWS IP ranges. Falling back to DNS resolution only." >&2
fi

# Resolve additional non-AWS domains and add IPs to the set
for domain in "${ALLOWED_DOMAINS[@]}"; do
    ips=$(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9]+\.' || true)
    for ip in $ips; do
        ipset add allowed_ips "$ip/32" -exist
    done

    # Also resolve CNAME targets
    cnames=$(dig +short CNAME "$domain" 2>/dev/null || true)
    for cname in $cnames; do
        cname_ips=$(dig +short A "$cname" 2>/dev/null | grep -E '^[0-9]+\.' || true)
        for ip in $cname_ips; do
            ipset add allowed_ips "$ip/32" -exist
        done
    done
done

# Flush existing OUTPUT rules
iptables -F OUTPUT

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established/related connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (UDP and TCP port 53)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow whitelisted IPs
iptables -A OUTPUT -m set --match-set allowed_ips dst -j ACCEPT

# Drop everything else
iptables -A OUTPUT -j DROP

echo "Firewall initialized: $(ipset list allowed_ips -terse | grep 'Number of entries' | awk '{print $NF}') IPs whitelisted"
