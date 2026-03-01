FROM node:20

# System packages + firewall dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    less \
    procps \
    sudo \
    man-db \
    unzip \
    gnupg2 \
    nano \
    vim \
    fzf \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Go
ARG GO_VERSION=1.22.5
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
    | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Allow node user to run firewall script without password
RUN echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh, /usr/sbin/iptables, /usr/sbin/iptables *" > /etc/sudoers.d/node-firewall \
    && chmod 0440 /etc/sudoers.d/node-firewall

# Install kiro-cli as node user
USER node
RUN curl -fsSL https://cli.kiro.dev/install | bash
ENV PATH="/home/node/.local/bin:${PATH}"

# Copy scripts
USER root
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/entrypoint.sh

# Set up workspace
RUN mkdir -p /workspace && chown node:node /workspace

USER node
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["kiro-cli", "chat"]
