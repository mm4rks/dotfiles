# Plan: Expand OpenCode Sandbox Tooling

## Objectives
Enrich the `opencode-sandbox` environment with essential development tools to enable the AI agent to perform complex tasks, including script analysis, compilation, and diagnostics.

## Implemented Toolset

### 1. Language Runtimes & Compilers
- **Python**: `python3` (v3.11), `pip`, `venv`. Aliased `python3` to `python`.
- **C/C++**: `gcc`, `g++`, `make`, `build-essential`, `libc6-dev`.

### 2. Utilities & Diagnostics
- **Networking**: `curl`, `wget`, `ca-certificates`.
- **System**: `procps` (`ps`, `top`), `unzip`, `jq`.
- **Search**: `ripgrep` (`rg`), `fd-find` (aliased to `fd`).

### 3. Static Analysis
- **Shell**: `shellcheck` (specifically for dotfiles development).

## Implementation Details

- **Dockerfile**: Updated `docker/opencode/Dockerfile` to install all tools in a single layer.
- **Symlinks**: Added symlinks in `/usr/local/bin` to ensure consistent tool names (`python`, `fd`).
- **Persistence**: These tools are baked into the `opencode-sandbox:latest` image and are available across all project mounts.

## Verification Results
Verified the availability of all tools via `docker run --entrypoint bash`:
- Python 3.11.2
- GCC 12.2.0
- Make 4.3
- fd 8.6.0
- ripgrep 13.0.0
- ShellCheck 0.9.0
- jq-1.6
- curl 7.88.1
