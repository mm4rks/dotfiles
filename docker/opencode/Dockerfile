FROM node:22-slim

# Install system dependencies, development tools, and language runtimes
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    git \
    curl \
    wget \
    ca-certificates \
    gpg \
    # Diagnostics and utilities
    procps \
    unzip \
    jq \
    # Search and linting
    ripgrep \
    fd-find \
    shellcheck \
    # Python development
    python3 \
    python3-pip \
    python3-venv \
    # C/C++ development
    build-essential \
    gcc \
    g++ \
    make \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell from Microsoft's Debian repository
RUN wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/*

# Symlinks for common tool names
RUN ln -s /usr/bin/python3 /usr/local/bin/python && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd

# Install opencode and auth plugins
RUN npm install -g opencode-ai opencode-gemini-auth opencode-anthropic-auth

ENTRYPOINT ["opencode"]
