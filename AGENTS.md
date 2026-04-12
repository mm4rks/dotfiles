# Agent Guidelines for Dotfiles Repository

This document outlines the standard operating procedures, architectural patterns, and code style guidelines for AI coding agents operating within this dotfiles repository. It serves as the definitive source of truth for contributing safe, idiomatic, and consistent code to this project.

## 1. Build, Lint, and Test Commands

This repository relies heavily on Docker for robust, cross-distribution testing of the setup scripts. The testing strategy involves building Docker images for different Linux distributions and executing the core setup scripts within those ephemeral, clean containers to verify functionality and cross-platform compatibility.

### 1.1. Testing All Distributions
To run the full comprehensive test suite across all supported distributions (currently Ubuntu, Kali, and Parrot), execute the provided test runner script from the repository root:
```bash
./test_runner.sh
```
This script will sequentially build the target environments defined in `Dockerfile.test`. The script will exit with a non-zero status immediately if any of the target builds fail, ensuring that any cross-platform regressions are caught very early in the development lifecycle.

### 1.2. Running a Single Test
When debugging or developing for a specific target OS, testing the entire suite can be slow and unnecessary. If you need to test a specific distribution without running the entire test suite, invoke Docker directly using the explicit targets defined in `Dockerfile.test`:

```bash
# Test strictly on Ubuntu
docker build --target ubuntu-test -t dotfiles-tester-ubuntu-test -f Dockerfile.test .

# Test strictly on Kali Linux (Standard Setup)
docker build --target kali-test -t dotfiles-tester-kali-test -f Dockerfile.test .

# Test strictly on Kali Linux (Guest/Sandbox Setup)
docker build --target kali-guest-test -t dotfiles-tester-kali-guest -f Dockerfile.test .

# Test strictly on Parrot OS
docker build --target parrot-test -t dotfiles-tester-parrot-test -f Dockerfile.test .
```
This is the preferred way to iteratively test fixes for a single broken environment.

### 1.3. Linting
While there is no automated linting pipeline integrated directly into the `test_runner.sh` execution, all Bash scripts MUST be strictly compliant with `shellcheck`. Before committing any modifications or creating new `.sh` files, verify the scripts manually using the CLI:
```bash
shellcheck script_name.sh
```
Address all warnings and errors surfaced by `shellcheck`. Use appropriate `# shellcheck disable=SCXXXX` directives only if the warning is strictly a false positive and the reasoning is clear.

### 1.4. Build Process
This repository does not have a traditional "build" step for the dotfiles themselves, but any changes to the `Dockerfile.test` or the core setup logic should be verified by rebuilding the test images. If you modify a dependency in `scripts/install_base_deps.sh`, you MUST run the relevant Docker test to ensure the dependency is correctly resolved.

## 2. Code Style Guidelines

The following conventions must be strictly followed when writing or modifying Bash scripts and configuration files in this repository.

### 2.1. Bash Strict Mode
All executable scripts must begin with the appropriate strict mode configuration to ensure robust error handling and prevent unexpected behavior cascading through the setup process:
```bash
#!/bin/bash
set -euo pipefail
```
- `-e`: Exit immediately if a pipeline, list, or compound command exits with a non-zero status.
- `-u`: Treat unset variables and parameters as an error when performing parameter expansion.
- `-o pipefail`: Return value of a pipeline is the status of the last command to exit with a non-zero status.

### 2.2. Idempotency and Command Verification
- **Idempotency:** Scripts must be completely safe to run multiple times without causing negative side effects, duplicating configuration lines, or crashing. Always check if a binary or tool is already installed before attempting an installation.
- **Verification:** Use the `command_exists` utility defined in `scripts/lib.sh` instead of raw `command -v`:
  ```bash
  if command_exists tool_name; then
      log "tool_name is already installed. Skipping."
      return 0
  fi
  ```
- **Utility Functions:** Leverage `scripts/lib.sh` for common tasks:
    - `download_and_verify <url> <path> [sha256sum]`: Safe downloads with optional checksum verification.
    - `user_in_group <group>`: Check if the current user belongs to a specific group (e.g., `docker`).

### 2.3. Error Handling & Cleanup
- **Graceful Failures:** Use `if ! command; then` constructs to handle potential failures and provide graceful fallbacks (e.g., trying alternative package managers or repositories).
- **Cleanup with Trap:** When using temporary resources, always use `trap` to ensure cleanup even if the script fails:
  ```bash
  local TEMP_DIR
  TEMP_DIR="$(mktemp -d)"
  trap "rm -rf '$TEMP_DIR'" RETURN
  ```

### 2.4. Logging Conventions
Do not use raw `echo` or `printf` commands for status updates in the main execution flow. Use the centralized, color-coded logging functions defined within `scripts/lib.sh`:
- `log "Message"`: For standard, expected informational output (Green).
- `warn "Message"`: For non-critical warnings or fallback notifications (Yellow).
- `error "Message"`: For critical failures. This function automatically invokes `exit 1` (Red).

### 2.5. Functions and Structure
- **Modularity:** Encapsulate logical, distinct units of work into well-named, descriptive functions (e.g., `install_docker_official()`, `stow_dotfiles()`).
- **Main Function:** Every executable script must define a `main()` function at the bottom of the file as the entry point:
  ```bash
  main() {
      # Core logic and function calls here
  }
  main "$@"
  ```

### 2.6. Variables and Scope
- **Global Variables:** Use `UPPER_CASE` for global configuration (e.g., `REPO_DIR`, `REAL_USER`).
- **Local Variables:** ALWAYS tightly scope variables within functions using the `local` keyword:
  ```bash
  local target_path="/tmp/output"
  ```
- **Quoting:** Always quote variable expansions to prevent word splitting: `"$USER_HOME"`, `"${PROFILES[@]}"`.

### 2.7. Paths and Temporary Directories
- **Dynamic Repository Root:** Scripts should dynamically determine their absolute execution path:
  ```bash
  REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  ```
- **Absolute Paths:** Always use absolute paths for file operations to avoid ambiguity during nested script calls.

### 2.8. Package and Dependency Management
- **Apt:** Use for core system dependencies (libatomic1, sudo, curl, etc.).
- **Mise:** Use for tool-specific versions (Neovim, Java, etc.) to maintain environment consistency.
- **Custom Scripts:** Add specialized tool installations under `scripts/install_<tool_name>.sh`.

### 2.9. Configuration Management
- **GNU Stow:** Used for managing configuration symlinks to the user's home directory in standard setups.
- **Sandbox/Guest Setup:** In `guest` mode, scripts must skip `stow` and instead use environment variables like `ZDOTDIR` and `XDG_CONFIG_HOME` to point to the repository's configuration files without modifying the system home.

### 2.10. Code Formatting
- **Indentation:** Use exactly 4 spaces for all indentation. NO hard tabs.
- **Control Structures:** Place `then` on the same line as `if`: `if [ condition ]; then`
- **Loops:** Place `do` on the same line as `for` or `while`: `for item in "${items[@]}"; do`

## 3. Environment Specifics

### 3.1. Profiles
- **Standard:** Full installation with sudo privileges and home directory symlinking via Stow.
- **Guest:** Sandbox mode for restricted environments. Skips sudo and Stow. Activated via `source activate.sh`.

### 3.2. Critical Variables
- `ZDOTDIR`: Redirects Zsh configuration to `zsh/` within the repo.
- `XDG_CONFIG_HOME`: Redirects application configs to `config/` within the repo.

## 4. Absolute System Constraints (Sandbox Mode)

- **Assume Failure**: Any system-level operation (e.g., `sudo`, `apt`, `stow`, `chown`, `chmod`) is guaranteed to fail in this environment. Do not try these commands, even to check if they work.
- **System Troubleshooting**: Do not attempt to troubleshoot system-level errors (e.g., missing system libraries, permission denied on root folders, kernel issues). These will always fail due to sandbox restrictions.
- **Delegate to Host**: If you require a system change (e.g., installing a dependency or fixing permissions), identify the necessary command and provide it to the user to run on their host system. Do not proceed until the user confirms the action has been taken on the host.
- **CRITICAL: NO SYSTEM TROUBLESHOOTING**:
    - **Zero Tolerance**: Never attempt to diagnose, verify, or troubleshoot the host system from the sandbox. This includes checking OS versions (`/etc/os-release`), package managers (`pacman`, `apt`), or hardware status (`nvidia-smi`, `lspci`).
    - **Hard Stop**: If a system-level tool or dependency is missing, STOP IMMEDIATELY. Identify the required change and provide the exact command for the user to run on their host. Do not attempt to "verify" if the command will work.
    - **Sandbox Isolation**: You are a guest in this environment. Treat the host as an opaque, external entity that only the user can modify.

## 5. External Agent Rules

Adhere strictly to the conventions defined in this `AGENTS.md` file. There are currently no explicit `.cursorrules` or `.github/copilot-instructions.md` configured. If they are added in the future, they should be integrated into this document to maintain a single source of truth for all autonomous agents.
