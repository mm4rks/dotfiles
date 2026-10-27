function ts() {
    tmux send-keys -t right "$@" C-m
} # Description: Send a command and its arguments to the tmux pane to the right

function swapctrl() {
    local arg="${1:l}"

    if [[ "$arg" == "off" ]]; then
        gsettings set org.gnome.desktop.input-sources xkb-options "[]"
        echo "[+] Key swap disabled."
    else
        gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:swapcaps']"
        echo "[+] Ctrl and Caps Lock swapped."
    fi
} # Description:  Swaps Ctrl and Caps Lock. Usage: swapctrl [off]

function rf() {
    local search_path="${1:-.}" #  default to the current directory ('.')
    local INITIAL_QUERY=""
    local RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"
    FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY' -- '$search_path'" \
        fzf --bind "change:reload:$RG_PREFIX {q} -- '$search_path' || true" \
            --ansi --disabled --query "$INITIAL_QUERY" \
            --height=50% --layout=reverse \
            --preview "${BAT_CMD:-cat} --color=always {1} --highlight-line {2}" \
            --preview-window "up,60%,border-bottom,+{2}+3/3,~3"
} # Description: Interactively search inside files in a directory (optional argument) with rg and fzf.

function secret() { 
  local length=${1:-32}
  tr -dc 'a-zA-Z0-9_' < /dev/urandom | head -c "$length"
} # Description: Create secret of length $1, or default to 32

function mcd() {
   mkdir -p "$1" && cd "$1"
} # Description: Create and navigate to a directory

function sshportfwd() {
    cat <<-EOF
	[1;36mSSH Port Forwarding Information[0m
	----------------------------------

	[1;32mLocal Port Forwarding (-L):[0m
	Usage: ssh -L <local_port>:<destination_host>:<destination_port> user@ssh_server
	[+] Example: ssh -L 8080:localhost:80 user@remote_host
	[+] Explanation: Forwards connections from your local port 8080 to port 80 on the remote host.

	[1;34mRemote Port Forwarding (-R):[0m
	Usage: ssh -R <remote_port>:<destination_host>:<destination_port> user@ssh_server
	[+] Example: ssh -R 8080:localhost:80 user@remote_host
	[+] Explanation: Forwards connections from port 8080 on the remote server to port 80 on your local machine.

	[1;35mDynamic Port Forwarding (SOCKS Proxy):[0m
	Usage: ssh -D <local_port> user@ssh_server
	[+] Example: ssh -D 1080 user@remote_host
	[+] Explanation: Creates a SOCKS proxy on local port 1080 that tunnels traffic through the SSH server.

	[1;36mNotes:[0m
	[i] Local (-L): Your Machine -> SSH Server -> Destination
	[i] Remote (-R): Remote Machine -> SSH Server -> Your Machine
	[i] Dynamic (-D): Your Machine (as proxy) -> SSH Server -> Anywhere
EOF
} # Description: Print a cheat sheet for SSH port forwarding.

function genhosts() {
    if [[ -z "$1" ]]; then
        echo "[i] Usage: genhosts <IP_ADDRESS>"
        return 1
    fi

    local ip_address="$1"
    local tmp_file
    tmp_file=$(mktemp /tmp/genhosts.XXXXXX)

    # zsh `always` block: cleans up on return or Ctrl+C without installing
    # a trap that would outlive this function in the interactive shell.
    {
        echo "[i] Generating hosts file for: $ip_address"
        if ! netexec smb "$ip_address" --generate-hosts-file "$tmp_file"; then
            echo "[!] Failed to generate hosts file. Check netexec command."
            return 1
        fi

        echo "[i] Appending generated entries to /etc/hosts..."
        # Use sudo with tee to append to a root-owned file.
        if sudo tee -a /etc/hosts < "$tmp_file" > /dev/null; then
            echo "[✓] /etc/hosts successfully updated. New entries:"
            cat "$tmp_file"
        else
            echo "[!] Failed to update /etc/hosts. Check sudo permissions."
            return 1
        fi
    } always {
        rm -f "$tmp_file"
    }
} # Description: Generate and append to /etc/hosts using netexec.

edit-command-line-tmux-float() {
  local TFILE=$(mktemp -t zshXXXXXX.sh)
  echo "$BUFFER" > "$TFILE"

  if [[ -n "$TMUX" ]]; then
    tmux display-popup -h 80% -w 80% -E "${EDITOR:-nvim} \"$TFILE\""
  else
    "${EDITOR:-nvim}" "$TFILE"
  fi

  BUFFER=$(cat "$TFILE")
  rm "$TFILE"

  zle redisplay
} # Description: Edit the current command in a floating tmux popup or external editor.


function tmux_smart_detach() {
  if [[ -z "$BUFFER" ]]; then
    if [[ -n "$TMUX" ]]; then
      local num_panes=$(tmux list-panes -F '#{pane_id}' | wc -l)
      local num_windows=$(tmux list-windows -F '#{window_id}' | wc -l)
      if [[ "$num_panes" -gt 1 ]]; then
        builtin exit
      else # num_panes == 1
        if [[ "$num_windows" -gt 1 ]]; then
          builtin exit
        else # num_windows == 1
          tmux detach-client
        fi
      fi
    else
      builtin exit
    fi
  else
    zle delete-char-or-list
  fi
} # Description: Smartly detach from tmux or exit shell.

function audit_npm() {
    local SEARCH_ALL="${1:-}"
    
    echo -e "\033[1;31m=== [Supply Chain Audit] Recursive NPM Dependencies ===\033[0m"
    
    # 1. Global
    echo -e "\n\033[1;32m[+] Auditing Global NPM Packages:\033[0m"
    npm list -g --all --depth=20 2>/dev/null || echo "    (No global packages found or npm error)"

    # 2. Deep Search
    if [[ "$SEARCH_ALL" == "--all" ]]; then
        local global_root
        global_root="$(npm root -g 2>/dev/null)"
        echo -e "\n\033[1;33m[!] Deep Scan: Searching for all 'node_modules' in \$HOME...\033[0m"
        find "$HOME" -name "node_modules" -type d -prune 2>/dev/null | while read -r nm_path; do
            # Skip the global root, already listed above
            [[ -n "$global_root" && "$nm_path" == "$global_root"* ]] && continue
            
            local pkg_dir=$(dirname "$nm_path")
            local lock_info=""
            [[ -f "$pkg_dir/package-lock.json" ]] && lock_info+="\033[0;32m[NPM-Lock]\033[0m "
            [[ -f "$pkg_dir/yarn.lock" ]] && lock_info+="\033[0;32m[Yarn-Lock]\033[0m "
            [[ -f "$pkg_dir/pnpm-lock.yaml" ]] && lock_info+="\033[0;32m[PNPM-Lock]\033[0m "

            echo -e "    Found: $pkg_dir ${lock_info:-\033[1;31m[!] NO LOCK FILE\033[0m}"
            # Try to list dependencies if it's a valid package directory
            if [[ -f "$pkg_dir/package.json" ]]; then
                (cd "$pkg_dir" && npm list --all --depth=5 2>/dev/null | sed 's/^/      /')
            else
                echo "      (No package.json found in $pkg_dir)"
            fi
        done
    fi
    echo -e "\n\033[1;31m=== Audit Complete ===\033[0m"
} # Description: Audit all recursive NPM dependencies for supply chain incident response. Usage: audit_npm [--all]


function compress() {
    if [[ -z "$1" ]]; then
        echo "Usage: compress <file/dir>"
        return 1
    fi
    local target="$1"
    target="${target%/}"
    tar -czvf "${target}.tar.gz" "$target"
} # Description: Create a .tar.gz archive from a file or directory.

function decompress() {
    if [[ -z "$1" ]]; then
        echo "Usage: decompress <file.tar.gz>"
        return 1
    fi
    tar -xzvf "$1"
} # Description: Expand a .tar.gz archive.

function tdl() {
    local ai_agent="${1:-c}"
    
    # Check if we are inside a tmux session
    if [[ -n "$TMUX" ]]; then
        echo "[-] You are already inside a Tmux session."
        return 1
    fi
    
    # Start a new tmux session named 'dev_layout' in detached mode
    tmux new-session -d -s dev_layout 2>/dev/null || true
    
    # Send editor command to first pane
    tmux send-keys -t dev_layout "${EDITOR:-nvim} ." C-m
    
    # Split horizontally (right pane)
    local ai_pane=$(tmux split-window -h -t dev_layout -P -F '#{pane_id}')
    
    # Run the AI agent in the right pane
    if [[ "$ai_agent" == "c" ]]; then
        tmux send-keys -t "$ai_pane" "opencode" C-m
    elif [[ "$ai_agent" == "cx" ]]; then
        tmux send-keys -t "$ai_pane" "claude" C-m
    elif [[ "$ai_agent" == "agy" ]]; then
        tmux send-keys -t "$ai_pane" "agy" C-m
    else
        tmux send-keys -t "$ai_pane" "$ai_agent" C-m
    fi
    
    # Split the right pane vertically for a standard terminal
    tmux split-window -v -t "$ai_pane"
    
    # Attach to the session
    tmux attach-session -t dev_layout
} # Description: Tmux Dev Layout with editor, AI agent, and terminal.
