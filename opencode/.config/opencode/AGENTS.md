# OpenCode Global Sandbox Rules

These rules apply to every OpenCode session launched from this dotfiles setup.

## Absolute System Constraints

- **Assume Failure**: Any system-level operation (e.g., `sudo`, `apt`, `stow`, `chown`, `chmod`) is guaranteed to fail in this environment.
- **Do Not Attempt**: Do not try these commands, even to check if they work.
- **System Troubleshooting**: Do not attempt to troubleshoot system-level errors (e.g., missing system libraries, permission denied on root folders, kernel issues). These will always fail due to sandbox restrictions.
- **Delegate to Host**: If you require a system change (e.g., installing a dependency or fixing permissions), identify the necessary command and provide it to the user to run on their host system. Do not proceed until the user confirms the action has been taken on the host.
- **CRITICAL: NO SYSTEM TROUBLESHOOTING**:
    - **Zero Tolerance**: Never attempt to diagnose, verify, or troubleshoot the host system from the sandbox. This includes checking OS versions (`/etc/os-release`), package managers (`pacman`, `apt`), or hardware status (`nvidia-smi`, `lspci`).
    - **Hard Stop**: If a system-level tool or dependency is missing, STOP IMMEDIATELY. Identify the required change and provide the exact command for the user to run on their host. Do not attempt to "verify" if the command will work.
    - **Sandbox Isolation**: You are a guest in this environment. Treat the host as an opaque, external entity that only the user can modify.

## Sandbox environment

- You are already running inside the OpenCode Docker sandbox. Do not try to launch, rebuild, inspect, or manage Docker or Podman unless the user explicitly asks you to work on the sandbox itself.
- The active project directory is mounted into the sandbox as your working tree. Treat the mounted workspace as the source of truth.
- `~/share` is a persistent read-write exchange directory shared across projects and OpenCode sessions. Use it for artifacts or notes that should survive outside the current project. In the sandbox, this is always accessible at `/home/node/share` (or `~/share`).

## Default command behavior

- Do not run `docker`, `docker compose`, `podman`, or similar sandbox-management commands unless the user explicitly asks.
- Do not run `git pull`, `git push`, or other remote-sync commands unless the user explicitly asks.
- Prefer working with the files and tools already available inside the current sandbox instead of trying to change the host environment.

## Development Workflow (Repository First)

- **Always prioritize the repository**: When making changes to configurations (e.g., opencode, nvim, zsh), always modify the files within the repository (`/home/user/.dotfiles`) rather than their target locations in the system (e.g., `~/.config/`). 
- **Stow-awareness**: This repository is designed to be stowed. Ensure any new configuration files are placed in the correct package directory (e.g., `opencode/`, `nvim/`) following the internal directory structure that mirrors the intended target location.
- **Persistence**: Changes made to the repository are permanent and will be reflected in future sessions after being stowed. System-level changes may be lost or inconsistent with the repository state.

## TTS Notifications (DEPRECATED in 00-Organization)
- Do NOT use TTS in the 00-Organization workspace unless explicitly requested.

