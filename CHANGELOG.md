# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-03-01

### Added

- Dependabot security updates of node from 20 to 25 for claude-code and kiro-cli.

## [0.2.0] - 2026-03-01

### Added

- Dependabot configuration for automated dependency security scanning (`.github/dependabot.yml`)

## [0.1.0] - 2026-03-01

### Added

- **Claude Code container** — Sandboxed Podman container for running Claude Code
  - Node.js 20, Python 3, Go toolchain
  - iptables firewall with domain-based whitelist (Anthropic APIs, npm, GitHub, PyPI, Go modules)
  - Persistent credentials via named Podman volume
  - Automatic `.claude.json` persistence via symlink into volume
- **Kiro CLI container** — Sandboxed Podman container for running Kiro CLI
  - Node.js 20, Python 3, Go toolchain
  - iptables firewall using official AWS IP ranges plus dev domain whitelist
  - Persistent credentials and config via two named Podman volumes
  - Automatic device-flow login when not authenticated
- **Common features across both containers**
  - `run.sh` launch script with `--build`, `--shell`, `-p`, and `--no-firewall` flags
  - File sandboxing via bind mount of current directory to `/workspace`
  - Non-root `node` user
  - Graceful firewall fallback if `NET_ADMIN` capability is missing
