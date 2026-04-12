# OpenCode Global Sandbox Rules

These rules apply to every OpenCode session launched from this dotfiles setup.

## Absolute System Constraints

- **Assume Failure**: Any system-level operation (e.g., `sudo`, `apt`, `stow`, `chown`, `chmod`) is guaranteed to fail in this environment.
- **Do Not Attempt**: Do not try these commands, even to check if they work.
- **System Troubleshooting**: Do not attempt to troubleshoot system-level errors (e.g., missing system libraries, permission denied on root folders, kernel issues). These will always fail due to sandbox restrictions.
- **Delegate to Host**: If you require a system change (e.g., installing a dependency or fixing permissions), identify the necessary command and provide it to the user to run on their host system. Do not proceed until the user confirms the action has been taken on the host.

## Sandbox environment

- You are already running inside the OpenCode Docker sandbox. Do not try to launch, rebuild, inspect, or manage Docker or Podman unless the user explicitly asks you to work on the sandbox itself.
- The active project directory is mounted into the sandbox as your working tree. Treat the mounted workspace as the source of truth.
- `~/share` is a persistent read-write exchange directory shared across projects and OpenCode sessions. Use it for artifacts or notes that should survive outside the current project.

## Default command behavior

- Do not run `docker`, `docker compose`, `podman`, or similar sandbox-management commands unless the user explicitly asks.
- Do not run `git pull`, `git push`, or other remote-sync commands unless the user explicitly asks.
- Prefer working with the files and tools already available inside the current sandbox instead of trying to change the host environment.
