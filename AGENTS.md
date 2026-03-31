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

# Test strictly on Kali Linux
docker build --target kali-test -t dotfiles-tester-kali-test -f Dockerfile.test .

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
- `-o pipefail`: Return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status.

### 2.2. Error Handling & Idempotency
- **Idempotency:** Scripts must be completely safe to run multiple times without causing negative side effects, duplicating configuration lines, or crashing. Always check if a binary or tool is already installed before attempting an installation:
  ```bash
  if command -v tool_name &>/dev/null; then
      log "tool_name is already installed. Skipping."
      return 0
  fi
  ```
- **Graceful Failures:** Use `if ! command; then` constructs to handle potential failures and provide graceful fallbacks (e.g., trying alternative package managers or repositories) rather than abruptly crashing the setup, unless the failure is absolutely critical to the core system.

### 2.3. Logging Conventions
Do not use raw `echo` or `printf` commands for status updates in the main execution flow. Use the centralized, color-coded logging functions defined within the setup scripts:
- `log "Message"`: For standard, expected informational output (prints in Green).
- `warn "Message"`: For non-critical warnings or fallback notifications (prints in Yellow).
- `error "Message"`: For critical failures. This function automatically invokes `exit 1` after printing the message (prints in Red).

### 2.4. Functions and Structure
- **Modularity:** Encapsulate logical, distinct units of work into well-named, descriptive functions (e.g., `install_docker_official()`, `stow_dotfiles()`). Do not write long procedural scripts.
- **Main Function:** Every executable script must define a `main()` function at the bottom of the file. This function acts as the entry point and is invoked with all script arguments passed down:
  ```bash
  main() {
      # Core logic and function calls here
  }
  main "$@"
  ```

### 2.5. Variables and Scope
- **Global Variables:** Use `UPPER_CASE` syntax for global configuration variables (e.g., `REPO_DIR`, `REAL_USER`, `DISTROS`).
- **Local Variables:** Use `UPPER_CASE` or `lower_case` but ALWAYS tightly scope variables within functions using the `local` keyword to prevent global namespace pollution and unintended collisions:
  ```bash
  local TEMP_DIR=""
  ```
- **Quoting:** Always quote variable expansions to prevent word splitting and globbing issues, especially when dealing with user input or file paths (e.g., `"$USER_HOME"`, `"${PROFILES[@]}"`).

### 2.6. Paths and Temporary Directories
- **Dynamic Repository Root:** Scripts should dynamically determine their absolute execution path rather than relying on an assumed current working directory:
  ```bash
  REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  ```
- **Temporary Files:** When generating temporary directories or downloading ephemeral files via `wget`/`curl`, use `mktemp` and guarantee their cleanup via the `trap` command. Ensure the cleanup fires upon function return:
  ```bash
  local TEMP_DIR=""
  TEMP_DIR="$(mktemp -d)"
  trap "rm -rf '$TEMP_DIR'" RETURN # Cleanup when the function scope exits
  ```

### 2.7. Privilege Management
The `setup.sh` script is the primary entry point and handles elevation internally using `sudo` for system-level phases (Phase 1).
- **Standard Setup:** Executes all phases, including system dependencies and `GNU Stow` for home directory symlinks.
- **Guest/Sandbox Mode:** If the `guest` profile is passed to `setup.sh`, it skips all `sudo` operations and does NOT use `stow`. Instead, it prepares a sandboxed environment within the repository that can be activated using `source activate.sh`.

### 2.8. Configuration Management
- This repository utilizes `GNU Stow` for managing configuration symlinks to the user's home directory in standard setups.
- For Guest/Sandbox setups, environment variables like `ZDOTDIR` and `XDG_CONFIG_HOME` are used to redirect tools to the repository's configuration files without modifying the system's home directory.
- Ensure dotfiles are structured logically (e.g., `nvim/`, `tmux/`, `zsh/`) to support both `stow` and sandboxed redirection.

### 2.9. Code Formatting
- **Indentation:** Use exactly 4 spaces for all indentation. Do not use hard tabs under any circumstances.
- **Control Structures:** Place `then` on the exact same line as `if`, cleanly separated by a semicolon: `if [ condition ]; then`
- **Loops:** Place `do` on the exact same line as `for` or `while`: `for item in "${items[@]}"; do`

### 2.10. External Agent Rules
There are currently no explicit `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md` configured for this repository. Adhere safely and solely to the conventions defined inside this `AGENTS.md` file when operating autonomously.
