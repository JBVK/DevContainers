# Claude Code Dev Container

A Podman container for running [Claude Code](https://claude.ai/code) as a sandboxed AI agent. Claude Code edits your real project files via a bind mount, but is restricted from accessing anything outside the mounted directory. A built-in firewall limits network access to only the services Claude Code needs.

## Why use this?

- **File sandboxing** — Claude Code can only see and modify files in the directory you launch from. It cannot access your home directory, other projects, or system files.
- **Network restrictions** — An iptables firewall blocks all outbound traffic except whitelisted domains (Anthropic APIs, npm, GitHub, PyPI, Go modules). Claude Code cannot make arbitrary HTTP requests.
- **Reproducible environment** — A consistent Linux environment with Node.js, Python, and Go pre-installed, regardless of your host setup.
- **Persistent auth** — Log in once. Your credentials are stored in a named Podman volume and survive container rebuilds.
- **Easy cleanup** — Containers are removed on exit (`--rm`). No leftover state on your host beyond the config volume and your project files.

## Security disclaimer

This container adds a layer of isolation, but **we do not guarantee its security**. Specifically:

- The firewall is based on DNS resolution at container startup. IP addresses can change, and DNS-based filtering has known limitations.
- The container runs with `NET_ADMIN` and `NET_RAW` capabilities, which expand the container's privileges beyond the default.
- Bind-mounting your project directory gives Claude Code full read/write access to everything in that directory.
- This is not a substitute for reviewing AI-generated changes before committing them.
- Use at your own risk. This project is provided as-is, without warranty of any kind.

## Prerequisites

- [Podman](https://podman.io/) installed and running
- A Claude Code account (Pro, Max, Team, or Enterprise plan, or API credits)

### Installing Podman on macOS

```bash
brew install podman
podman machine init
podman machine start
```

## Quick start

```bash
# Navigate to any project directory
cd ~/my-project

# Run Claude Code in a container
/path/to/run.sh
```

The image builds automatically on first run. On subsequent runs it starts immediately.

## Usage

```bash
# Interactive mode (default)
./run.sh

# Force rebuild the image
./run.sh --build

# Headless mode — pass a prompt directly
./run.sh -p "refactor the auth module to use JWT"

# Drop into a bash shell inside the container
./run.sh --shell
```

### First-time setup

The first time you run the container, Claude Code will ask you to log in:

1. Run `./run.sh`
2. Follow the login prompts (OAuth flow)
3. Your credentials are saved in the `claude-code-config` Podman volume
4. All future runs will use the saved credentials automatically

## What's in the container

| Tool | Version |
|------|---------|
| Node.js | 20.x |
| Python | 3.x |
| Go | 1.22.5 |
| git | Latest from apt |
| Claude Code | Latest (configurable) |
| Editors | nano, vim |
| Utilities | curl, jq, fzf, unzip |

## How it works

### File access

Your current working directory is mounted to `/workspace` inside the container. Any changes Claude Code makes appear on your host immediately, and vice versa. Nothing outside that directory is accessible.

### Network firewall

On startup, the container resolves a whitelist of domains to IP addresses and configures iptables rules:

**Allowed:**
- Anthropic APIs (`api.anthropic.com`, `claude.ai`)
- npm registry (`registry.npmjs.org`)
- GitHub (`github.com`, `api.github.com`, `raw.githubusercontent.com`)
- PyPI (`pypi.org`, `files.pythonhosted.org`)
- Go modules (`proxy.golang.org`, `sum.golang.org`)
- Docker Hub, Google downloads

**Blocked:** Everything else.

### Credential persistence

Claude Code stores credentials in two locations:
- `~/.claude/` — stored in the `claude-code-config` named volume
- `~/.claude.json` — automatically symlinked into the volume by the entrypoint script

Both persist across container restarts and image rebuilds.

## Customization

### Pin a specific Claude Code version

```bash
podman build --build-arg CLAUDE_CODE_VERSION=2.1.63 -t claude-code-dev .
```

### Pin a specific Go version

```bash
podman build --build-arg GO_VERSION=1.23.0 -t claude-code-dev .
```

### Add domains to the firewall whitelist

Edit `init-firewall.sh` and add domains to the `ALLOWED_DOMAINS` array, then rebuild:

```bash
./run.sh --build
```

## File structure

```
Dockerfile         — Container image definition
entrypoint.sh      — Startup script (firewall init + credential persistence)
init-firewall.sh   — iptables/ipset firewall configuration
run.sh             — Host-side launch script
CLAUDE.md          — Instructions for Claude Code when working in this repo
```

## Troubleshooting

### "Firewall init failed" warning

The container needs `NET_ADMIN` and `NET_RAW` capabilities for the firewall. The `run.sh` script adds these automatically. If you run the container manually, include `--cap-add=NET_ADMIN --cap-add=NET_RAW`.

### Credentials not persisting

Check that the volume exists:

```bash
podman volume inspect claude-code-config
```

If it's missing, run `./run.sh` and log in again. The volume is created automatically.

### Permission errors during build

If `npm install -g` fails with `EACCES`, ensure the Dockerfile runs that step as root (before the `USER node` directive).

## License

This project is provided as-is, without warranty. Use at your own risk.
