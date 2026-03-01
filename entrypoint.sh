#!/usr/bin/env bash
set -euo pipefail

# Initialize firewall (runs as root via sudo)
if ! sudo /usr/local/bin/init-firewall.sh 2>/dev/null; then
    echo "WARNING: Firewall init failed (missing NET_ADMIN capability?). Running without network restrictions." >&2
fi

# Persist .claude.json across container restarts.
# Claude Code stores this at ~/.claude.json (outside the ~/.claude/ volume),
# so we symlink it into the persisted volume.
CLAUDE_JSON="$HOME/.claude.json"
CLAUDE_JSON_PERSISTED="$HOME/.claude/.claude.json"
if [[ ! -L "$CLAUDE_JSON" ]]; then
    # First run after login: move existing file into the volume
    if [[ -f "$CLAUDE_JSON" ]]; then
        mv "$CLAUDE_JSON" "$CLAUDE_JSON_PERSISTED"
    fi
    # Restore from backup if no persisted copy exists
    if [[ ! -f "$CLAUDE_JSON_PERSISTED" ]]; then
        BACKUP=$(ls -t "$HOME/.claude/backups/.claude.json.backup."* 2>/dev/null | head -1)
        if [[ -n "$BACKUP" ]]; then
            cp "$BACKUP" "$CLAUDE_JSON_PERSISTED"
        fi
    fi
    # Create symlink so Claude Code reads/writes to the persisted location
    if [[ -f "$CLAUDE_JSON_PERSISTED" ]]; then
        ln -sf "$CLAUDE_JSON_PERSISTED" "$CLAUDE_JSON"
    fi
fi

# Execute the requested command (default: claude)
exec "$@"
