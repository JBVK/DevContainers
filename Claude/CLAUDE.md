# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Claude Code Dev Container — a Podman container for running Claude Code as a sandboxed AI agent. Part of the JBVK DevContainers project.

The container mounts the host's current working directory so Claude Code edits real files, but cannot access anything outside that directory. A firewall restricts network access to whitelisted domains only.

## Architecture

```
Dockerfile          — Container image (node:20 + Python, Go, Rust, Claude Code)
init-firewall.sh    — iptables/ipset firewall setup (whitelists dev domains)
run.sh              — Host-side launch script (builds image, runs container)
```

**Key design decisions:**
- Base image: `node:20` (Debian-based, provides Node.js + npm)
- Non-root user: `node` (comes with base image)
- Auth persistence: named Podman volume `claude-code-config` mounted to `~/.claude/`
- File sandboxing: bind mount of `$(pwd)` to `/workspace`
- Firewall: iptables + ipset with domain-based whitelist

## Build & Run

```bash
# Build the image
podman build -t claude-code-dev .

# Run interactively (from any project directory)
./run.sh

# Rebuild before running
./run.sh --build

# Headless mode with a prompt
./run.sh -p "fix the bug in main.py"

# Drop into a shell instead of Claude Code
./run.sh --shell
```

## Conventions

- **Container runtime:** Podman (not Docker)
- The firewall script runs inside the container as root via sudo
- Go version is pinned via `GO_VERSION` build arg in the Dockerfile
- Claude Code version is configurable via `CLAUDE_CODE_VERSION` build arg (defaults to `latest`)
