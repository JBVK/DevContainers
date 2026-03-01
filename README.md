# JBVK AI Agent Dev Containers

Sandboxed [Podman](https://podman.io/) containers for running AI coding agents. Each container isolates the agent's file access to your current working directory and restricts network access with an iptables firewall.

## Available Containers

| Container | Agent | Description |
|-----------|-------|-------------|
| [Claude](./claude-code/) | [Claude Code](https://claude.ai/code) | Anthropic's AI coding agent |
| [kiro-cli](./kiro-cli/) | [Kiro CLI](https://kiro.dev/cli/) | AWS-powered AI coding agent |

## What these containers do

- **File sandboxing** — The agent can only read and write files in the directory you launch from. Your home directory, system files, and other projects are not accessible.
- **Network firewall** — Outbound traffic is restricted to the APIs and registries the agent needs (Anthropic/AWS APIs, npm, GitHub, PyPI, Go modules). Arbitrary HTTP requests are blocked.
- **Persistent credentials** — Authentication is stored in named Podman volumes. Log in once, and it persists across container rebuilds.
- **Clean ephemeral containers** — Containers are removed on exit. No leftover state beyond your project files and the credential volume.
- **Polyglot dev environment** — Each container comes with Node.js 20, Python 3, Go, git, and common CLI tools pre-installed.

## Security disclaimer

These containers add a layer of isolation, but **we do not guarantee their security**.

- Firewalls are based on IP whitelisting, which has inherent limitations (IP changes, CDN overlap, etc.)
- Containers run with `NET_ADMIN` and `NET_RAW` capabilities for firewall setup
- Bind-mounting your project directory gives the agent full read/write access to that directory
- The Kiro CLI container whitelists all AWS IP ranges, which is a broad allowlist
- Headless mode (`-p`) grants the agent unrestricted permissions to execute commands and modify files without confirmation
- These containers are not a substitute for reviewing AI-generated code changes before committing them
- **Use at your own risk. This project is provided as-is, without warranty of any kind.**

## Prerequisites

- [Podman](https://podman.io/) installed and running

### macOS

```bash
brew install podman
podman machine init
podman machine start
```

## Quick start

Each container has its own `run.sh` script. Navigate to any project directory and run:

```bash
# Claude Code
/path/to/claude-code/run.sh

# Kiro CLI
/path/to/kiro-cli/run.sh
```

The image builds automatically on first run. See each container's README for authentication setup and full usage details.

## Common flags

All containers support the same flags:

| Flag | Description |
|------|-------------|
| `--build` | Force rebuild the container image |
| `--shell` | Drop into a bash shell instead of the agent |
| `-p "prompt"` | Run in headless mode with a prompt |
| `--no-firewall` | Disable the network firewall |

## Shell aliases

Add these to your `~/.zshrc` or `~/.bashrc` to run the agents from any directory. Replace the path with where you cloned this repo.

```bash
# AI Agent Dev Containers — update this path to where you cloned the repo
DEVCONTAINERS="$HOME/DevContainers"

# Claude Code
alias agentClaude="$DEVCONTAINERS/claude-code/run.sh"
alias agentClaudeShell="$DEVCONTAINERS/claude-code/run.sh --shell"
alias agentClaudeBuild="$DEVCONTAINERS/claude-code/run.sh --build"

# Kiro CLI
alias agentKiro="$DEVCONTAINERS/kiro-cli/run.sh"
alias agentKiroShell="$DEVCONTAINERS/kiro-cli/run.sh --shell"
alias agentKiroBuild="$DEVCONTAINERS/kiro-cli/run.sh --build"
```

Then reload your shell:

```bash
source ~/.zshrc  # or source ~/.bashrc
```

**Usage:**

```bash
cd ~/my-project
agentClaude                          # Start Claude Code
agentKiro                            # Start Kiro CLI
agentClaude -p "fix the tests"       # Headless mode
agentKiroShell                       # Shell into the Kiro container
```

## Project structure

```
claude-code/       — Claude Code dev container
  Dockerfile
  entrypoint.sh
  init-firewall.sh
  run.sh
kiro-cli/          — Kiro CLI dev container
  Dockerfile
  entrypoint.sh
  init-firewall.sh
  run.sh
```

## Contributing

Contributions are welcome. Each container follows the same pattern:

1. `Dockerfile` — Image definition with tools and the agent installed
2. `entrypoint.sh` — Startup logic (firewall, auth persistence)
3. `init-firewall.sh` — iptables/ipset firewall rules
4. `run.sh` — Host-side launch script with flag parsing

To add a new agent container, copy an existing one and adapt the install steps, firewall whitelist, and credential persistence for the new agent.

## License

This project is licensed under the [MIT License](./LICENSE). It is provided as-is, without warranty. Use at your own risk.
