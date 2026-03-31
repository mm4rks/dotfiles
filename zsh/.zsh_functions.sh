function ts() {
    tmux send-keys -t right "$@" C-m
} # Description: Send a command and its arguments to the tmux pane to the right

function swapctrl() {
    local arg="${1,,}"

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
        echo "[i] Usage: ${FUNCNAME[0]} <IP_ADDRESS>"
        return 1
    fi

    local ip_address="$1"
    local tmp_file
    tmp_file=$(mktemp /tmp/genhosts.XXXXXX)

    # Use a trap to ensure the temp file is cleaned up on script exit,
    # interrupt (Ctrl+C), or termination.
    trap 'rm -f "$tmp_file"' EXIT INT TERM

    echo "[i] Generating hosts file for: $ip_address"
    netexec smb "$ip_address" --generate-hosts-file "$tmp_file"

    if [[ $? -ne 0 ]]; then
        echo "[!] Failed to generate hosts file. Check netexec command."
        return 1
    fi

    echo "[i] Appending generated entries to /etc/hosts..."
    # Use sudo with tee to append to a root-owned file.
    sudo tee -a /etc/hosts < "$tmp_file" > /dev/null

    if [[ $? -eq 0 ]]; then
        echo "[✓] /etc/hosts successfully updated. New entries:"
        cat "$tmp_file"
    else
        echo "[!] Failed to update /etc/hosts. Check sudo permissions."
    fi
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


updatepwnbox() {
    # Configuration
    local TOKEN_FILE="$HOME/htb_token"
    local SSH_CONFIG="$HOME/.ssh/config"
    local BOOTSTRAP_URL="https://raw.githubusercontent.com/mm4rks/dotfiles/main/bootstrap.sh"
    
    if [[ ! -f "$TOKEN_FILE" ]]; then
        echo "[-] Error: $TOKEN_FILE not found."
        return 1
    fi

    # 1. Fetch credentials from the verified endpoint
    local TOKEN=$(tr -d '\n\r ' < "$TOKEN_FILE")
    local RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
        "https://labs.hackthebox.com/api/v4/pwnbox/status")

    # 2. Extract credentials
    local HOSTNAME=$(echo "$RESPONSE" | jq -r '.data.hostname // empty')
    local USER_NAME=$(echo "$RESPONSE" | jq -r '.data.username // empty')
    local PASSWORD=$(echo "$RESPONSE" | jq -r '.data.vnc_password // empty')

    if [[ -z "$HOSTNAME" || "$HOSTNAME" == "null" ]]; then
        echo "[-] Error: Could not retrieve active Pwnbox data."
        echo "[-] Response: $RESPONSE"
        return 1
    fi

    # 3. Update ~/.ssh/config for the 'htb' alias
    touch "$SSH_CONFIG"
    # Remove existing 'htb' block
    sed -i '/Host htb/,+6d' "$SSH_CONFIG"
    
    cat >> "$SSH_CONFIG" <<EOF
Host htb
    HostName $HOSTNAME
    User $USER_NAME
    ForwardX11 yes
    ForwardX11Trusted yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

    echo "[+] SSH alias 'htb' updated ($HOSTNAME)."
    echo "[+] Password: $PASSWORD (Copied to clipboard)"
    echo -n "$PASSWORD" | xc 2>/dev/null

    # 4. Remote Bootstrap: Curl script from GitHub and execute
    echo "[*] Executing remote bootstrap on 'htb'..."
    sshpass -p "$PASSWORD" ssh htb "nohup bash -c 'curl -sL $BOOTSTRAP_URL | bash' > /tmp/bootstrap.log 2>&1 &"
    echo "[+] Bootstrap process started in the background on 'htb'. You can disconnect."
} # Description: Fetches Pwnbox credentials, updates SSH config, and triggers remote bootstrap on Hack The Box Pwnbox.

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

    # 2. Mise
    local MISE_NPM_ROOT="$HOME/.local/share/mise/installs/npm"
    if [[ -d "$MISE_NPM_ROOT" ]]; then
        echo -e "\n\033[1;34m[+] Auditing Mise Managed NPM Packages ($MISE_NPM_ROOT):\033[0m"
        find "$MISE_NPM_ROOT" -maxdepth 2 -type d -name "node_modules" 2>/dev/null | while read -r nm_path; do
            local pkg_dir=$(dirname "$nm_path")
            local lock_info=""
            [[ -f "$pkg_dir/package-lock.json" ]] && lock_info+="\033[0;32m[NPM-Lock]\033[0m "
            [[ -f "$pkg_dir/yarn.lock" ]] && lock_info+="\033[0;32m[Yarn-Lock]\033[0m "
            [[ -f "$pkg_dir/pnpm-lock.yaml" ]] && lock_info+="\033[0;32m[PNPM-Lock]\033[0m "
            
            echo -e "    Location: $pkg_dir ${lock_info:-\033[1;31m[!] NO LOCK FILE\033[0m}"
            (cd "$pkg_dir" && npm list --all --depth=10 2>/dev/null | sed 's/^/      /')
        done
    fi

    # 3. Deep Search
    if [[ "$SEARCH_ALL" == "--all" ]]; then
        echo -e "\n\033[1;33m[!] Deep Scan: Searching for all 'node_modules' in \$HOME...\033[0m"
        find "$HOME" -name "node_modules" -type d -prune 2>/dev/null | while read -r nm_path; do
            # Skip paths already covered
            [[ "$nm_path" == "/usr/local/lib"* ]] && continue
            [[ "$nm_path" == "$MISE_NPM_ROOT"* ]] && continue
            
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

