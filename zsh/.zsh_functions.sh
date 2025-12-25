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
            --preview "bat --color=always {1} --highlight-line {2}" \
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
    tmux display-popup -E "${EDITOR:-nvim} \"$TFILE\""
  else
    "${EDITOR:-nvim}" "$TFILE"
  fi

  BUFFER=$(cat "$TFILE")
  rm "$TFILE"

  zle redisplay
} # Description: Edit the current command in a floating tmux popup or external editor.

# Create a new widget from the function
zle -N edit-command-line-tmux-float

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
    echo -n "$PASSWORD" | xclip -selection clipboard 2>/dev/null || echo -n "$PASSWORD" | pbcopy 2>/dev/null

    # 4. Remote Bootstrap: Curl script from GitHub and execute
    echo "[*] Executing remote bootstrap on 'htb'..."
    sshpass -p "$PASSWORD" ssh htb "nohup bash -c 'curl -sL $BOOTSTRAP_URL | bash' > /tmp/bootstrap.log 2>&1 &"
    echo "[+] Bootstrap process started in the background on 'htb'. You can disconnect."
} # Description: Fetches Pwnbox credentials, updates SSH config, and triggers remote bootstrap on Hack The Box Pwnbox.