# Plan: Move OpenCode to Docker Sandbox

## Overview
Move the `opencode` application and its AI toolchain into a secure, hardened Docker sandbox. This removes the native npm installation, aligns execution with the caller's UID/GID, and securely maps necessary directories while preventing container escapes.

## Phase 1: Native Installation Cleanup
- Edit `/home/user/.dotfiles/mise/dev.profile`.
- Remove the line `"npm:opencode-ai" = "latest"`.

## Phase 2: Dockerfile Configuration
- Create a new file: `/home/user/.dotfiles/opencode/Dockerfile`.
- Base image: `node:22-slim` (lightweight, highly compatible).
- Install `git` using `apt-get` (required by opencode for commit generation).
- Install plugins globally: `npm install -g opencode-ai opencode-gemini-auth opencode-anthropic-auth`.
- Set `ENTRYPOINT ["opencode"]`.

## Phase 3: Build Script Integration
- Create a new script: `/home/user/.dotfiles/scripts/install_opencode.sh`.
- Implement robust error handling (`set -euo pipefail`) and load repository logging functions.
- The script will execute `docker build` against `opencode/Dockerfile` and tag the image as `opencode-sandbox:latest`.
- Update `/home/user/.dotfiles/setup.sh` to execute `"${REPO_DIR}/scripts/install_opencode.sh"` in Phase 2 (User Environment).

## Phase 4: Wrapper Script Implementation
- Create a new script: `/home/user/.dotfiles/opencode/.local/bin/opencode`.
- This script acts as a seamless wrapper and will execute the Docker container with the following configuration:
  - **Identity**: `-u "$(id -u):$(id -g)"` to ensure the container runs as the calling user, avoiding root escalation.
  - **Environment**: `-e HOME="$HOME"` and `-e USER="$(whoami)"`.
  - **Directory Mapping**:
    - Current working directory: `-v "$PWD":"$PWD" -w "$PWD"` (Read-Write).
    - OpenCode config: `-v "$HOME/.config/opencode":"$HOME/.config/opencode":ro` (Read-Only).
    - Git config (Conditional): Mount `-v "$HOME/.gitconfig":"$HOME/.gitconfig":ro` if it exists.
  - **Network**: `--network host` to allow access to local services like Ollama mapped at `127.0.0.1:11434`.
  - **Hardening**: `--security-opt=no-new-privileges:true` and `--cap-drop=ALL`.
  - **Cleanup**: `--rm` to remove the container instance upon exit.
  - **TTY**: Automatically detects interactive terminals and applies `-it` flags conditionally.

## Phase 5: Testing
- Validate the bash scripts with `shellcheck`.
- Execute `./test_runner.sh` (or target the ubuntu tester via docker explicitly) to ensure the changes build and deploy cleanly across the sandbox environments.
