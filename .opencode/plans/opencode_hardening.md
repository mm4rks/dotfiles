# Plan: Hardening OpenCode Docker Sandbox

## Objectives
1.  **Home Directory Isolation**: Decouple the sandbox from the host `$HOME` using a persistent Docker volume.
2.  **Network Hardening**: Move from `--network host` to a bridge network with limited host service access via `host.docker.internal`.
3.  **Root Directory Guard**: Prevent execution of `opencode` in the user's base home directory.
4.  **Runtime Security**: Add temporary filesystem isolation for `/tmp`.

## Implementation Details

### Phase 1: Configuration Update
-   **File**: `/home/user/.dotfiles/opencode/.config/opencode/opencode.json`
-   **Change**: Update `baseURL` for the `ollama` provider.
-   **New Value**: `"baseURL": "http://host.docker.internal:11434/v1"`

### Phase 2: Wrapper Script Modification
-   **File**: `/home/user/.dotfiles/opencode/.local/bin/opencode`
-   **Guard Logic**:
    ```bash
    if [[ "$PWD" == "$HOME" ]]; then
        echo "Error: Running opencode in your HOME directory is forbidden for security reasons."
        echo "Please run it from within a specific project directory."
        exit 1
    fi
    ```
-   **Volume Setup**: Ensure the named volume exists before running.
    ```bash
    docker volume create opencode-home-cache >/dev/null
    ```
-   **Docker Run Changes**:
    -   Remove `--network host`.
    -   Add `--add-host=host.docker.internal:host-gateway`.
    -   Replace `-v "$HOME":"$HOME"` with `-v opencode-home-cache:"$HOME"`.
    -   Add `--tmpfs /tmp:exec`.
    -   Ensure the config mounts remain `:ro`.

### Phase 3: Verification
-   Test execution in `$HOME` (should fail).
    -   Test execution in a subfolder (should succeed).
    -   Test connectivity to Ollama (should succeed via `host.docker.internal`).
    -   Verify that files in `$HOME` (outside of `$PWD`) are invisible to the container.
