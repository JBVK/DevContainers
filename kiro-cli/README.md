# Kiro CLI Dev Container

A Podman container for running [Kiro CLI](https://kiro.dev/cli/) as a sandboxed AI agent. Kiro CLI edits your real project files via a bind mount, but is restricted from accessing anything outside the mounted directory. A built-in firewall limits network access to only the services Kiro CLI needs.

## Why use this?

- **File sandboxing** — Kiro CLI can only see and modify files in the directory you launch from. It cannot access your home directory, other projects, or system files.
- **Network restrictions** — An iptables firewall allows only AWS IP ranges and whitelisted dev domains (npm, GitHub, PyPI, Go modules). Kiro CLI cannot reach arbitrary external services.
- **Reproducible environment** — A consistent Linux environment with Node.js, Python, and Go pre-installed, regardless of your host setup.
- **Persistent auth** — Log in once. Your credentials are stored in named Podman volumes and survive container rebuilds.
- **Easy cleanup** — Containers are removed on exit (`--rm`). No leftover state on your host beyond the config volumes and your project files.

## Security disclaimer

This container adds a layer of isolation, but **we do not guarantee its security**. Specifically:

- The firewall whitelists all AWS IP ranges. This is a broad allowlist required for Kiro CLI to function, and it means the container can reach any AWS service.
- The container runs with `NET_ADMIN` and `NET_RAW` capabilities, which expand the container's privileges beyond the default.
- Bind-mounting your project directory gives Kiro CLI full read/write access to everything in that directory.
- This is not a substitute for reviewing AI-generated changes before committing them.
- Use at your own risk. This project is provided as-is, without warranty of any kind.

## Prerequisites

- [Podman](https://podman.io/) installed and running
- An AWS Builder ID or IAM Identity Center account for authentication

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

# Run Kiro CLI in a container
/path/to/run.sh
```

The image builds automatically on first run. On subsequent runs it starts immediately.

## Usage

```bash
# Interactive chat mode (default)
./run.sh

# Force rebuild the image
./run.sh --build

# Headless mode — pass a prompt directly
./run.sh -p "refactor the auth module to use JWT"

# Drop into a bash shell inside the container
./run.sh --shell

# Disable the network firewall
./run.sh --no-firewall
```

### First-time setup

The first time you run the container, you will be prompted to log in automatically using the device code flow:

1. Run `./run.sh`
2. A URL and code will be displayed
3. Open the URL in a browser on your host machine and enter the code
4. Select **Builder ID** or **IAM Identity Center**
5. Once authenticated, Kiro CLI starts automatically

Your credentials are saved in the `kiro-cli-data` Podman volume and persist across container restarts.

**Note:** GitHub/Google social login requires a browser and does not work inside the container. Use Builder ID or IAM Identity Center instead.

## What's in the container

| Tool | Version |
|------|---------|
| Node.js | 20.x |
| Python | 3.x |
| Go | 1.22.5 |
| git | Latest from apt |
| Kiro CLI | Latest |
| Editors | nano, vim |
| Utilities | curl, jq, fzf, unzip |

## How it works

### File access

Your current working directory is mounted to `/workspace` inside the container. Any changes Kiro CLI makes appear on your host immediately, and vice versa. Nothing outside that directory is accessible.

### Network firewall

On startup, the container downloads the [official AWS IP ranges](https://ip-ranges.amazonaws.com/ip-ranges.json) and configures iptables rules:

**Allowed:**
- All AWS IP ranges (required for Kiro CLI's various AWS service dependencies)
- Kiro domains (`kiro.dev`, `api.kiro.dev`, `auth.kiro.dev`)
- npm registry (`registry.npmjs.org`)
- GitHub (`github.com`, `api.github.com`, `raw.githubusercontent.com`)
- PyPI (`pypi.org`, `files.pythonhosted.org`)
- Go modules (`proxy.golang.org`, `sum.golang.org`)
- Docker Hub, Google downloads

**Blocked:** Everything else. For example, `curl https://example.com` will fail.

Use `--no-firewall` to disable network restrictions entirely.

### Credential persistence

Kiro CLI stores data in two locations, each with its own named Podman volume:

| Path | Volume | Contents |
|------|--------|----------|
| `~/.local/share/kiro-cli/` | `kiro-cli-data` | Auth tokens (SQLite database) |
| `~/.kiro/` | `kiro-cli-config` | Settings, MCP config, agents |

Both persist across container restarts and image rebuilds.

**Known limitation:** There is an upstream bug where Kiro CLI may not persist refreshed tokens back to the SQLite database. If you get logged out unexpectedly, run `kiro-cli login --use-device-flow` inside the container.

## Customization

### Pin a specific Go version

```bash
podman build --build-arg GO_VERSION=1.23.0 -t kiro-cli-dev .
```

### Add domains to the firewall whitelist

Edit `init-firewall.sh` and add domains to the `ALLOWED_DOMAINS` array, then rebuild:

```bash
./run.sh --build
```

## File structure

```
Dockerfile         — Container image definition
entrypoint.sh      — Startup script (firewall init + auto-login)
init-firewall.sh   — iptables/ipset firewall configuration
run.sh             — Host-side launch script
```

## Troubleshooting

### "Firewall init failed" warning

The container needs `NET_ADMIN` and `NET_RAW` capabilities for the firewall. The `run.sh` script adds these automatically. If you run the container manually, include `--cap-add=NET_ADMIN --cap-add=NET_RAW`.

### Login fails or asks to open a browser

Use **Builder ID** or **IAM Identity Center** when logging in — these support device code flow which works without a browser. GitHub/Google social login requires a browser and won't work inside the container.

### Slow responses or MCP warnings

If Kiro CLI is slow or shows "Failed to retrieve MCP settings", the firewall may be blocking required endpoints. Try running with `--no-firewall` to confirm, and if that fixes it, the AWS IP ranges may need updating — rebuild the image with `./run.sh --build`.

### Credentials not persisting

Check that the volumes exist:

```bash
podman volume inspect kiro-cli-data
podman volume inspect kiro-cli-config
```

If missing, run `./run.sh` and log in again. The volumes are created automatically.

### Logged out unexpectedly

This may be caused by an upstream bug where refreshed tokens are not written back to the database. Run `kiro-cli login --use-device-flow` inside the container to re-authenticate.

## License

This project is provided as-is, without warranty. Use at your own risk.
