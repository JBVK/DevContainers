# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

JBVK AI Agent Dev Containers — sandboxed Podman containers for running AI coding agents. This repo contains containers for Claude Code and Kiro CLI.

The containers mount the host's current working directory so the agent edits real files, but cannot access anything outside that directory. A firewall restricts network access to whitelisted domains/IPs only.

## Architecture

```
Claude/              — Claude Code dev container
  Dockerfile         — Container image (node:20 + Python, Go, cloud CLIs, Claude Code)
  entrypoint.sh      — Startup script (firewall init + credential persistence)
  init-firewall.sh   — iptables/ipset firewall setup (domain-based whitelist)
  run.sh             — Host-side launch script

kiro-cli/            — Kiro CLI dev container
  Dockerfile         — Container image (node:20 + Python, Go, cloud CLIs, Kiro CLI)
  entrypoint.sh      — Startup script (firewall init + auto device-flow login)
  init-firewall.sh   — iptables/ipset firewall setup (AWS IP ranges + domain whitelist)
  run.sh             — Host-side launch script
```

**Key design decisions:**
- Base image: `node:20` (Debian-based, provides Node.js + npm)
- Non-root user: `node` (comes with base image)
- Container runtime: Podman (not Docker)
- Auth persistence: named Podman volumes for credentials
- File sandboxing: bind mount of `$(pwd)` to `/workspace`
- Firewall: iptables + ipset (Claude uses domain whitelist, Kiro uses AWS IP ranges)
- Cloud CLIs: AWS, Azure, and Google Cloud pre-installed
- MCP support: uv/uvx + graphviz pre-installed for AWS MCP servers

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

# Drop into a shell instead of the agent
./run.sh --shell

# Disable the network firewall
./run.sh --no-firewall
```

## Conventions

- Container runtime is Podman (not Docker)
- The firewall script runs inside the container as root via sudo
- Go version is pinned via `GO_VERSION` build arg in the Dockerfiles
- Claude Code version is configurable via `CLAUDE_CODE_VERSION` build arg (defaults to `latest`)
- AWS MCP servers are run via `uvx awslabs.<server-name>@latest`
