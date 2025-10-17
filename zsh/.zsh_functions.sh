function ts() {
    tmux send-keys -t right "$@" C-m
} # Description: Send a command and its arguments to the tmux pane to the right

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
	\033[1;36mSSH Port Forwarding Information\033[0m
	----------------------------------

	\033[1;32mLocal Port Forwarding (-L):\033[0m
	Usage: ssh -L <local_port>:<destination_host>:<destination_port> user@ssh_server
	[+] Example: ssh -L 8080:localhost:80 user@remote_host
	[+] Explanation: Forwards connections from your local port 8080 to port 80 on the remote host.

	\033[1;34mRemote Port Forwarding (-R):\033[0m
	Usage: ssh -R <remote_port>:<destination_host>:<destination_port> user@ssh_server
	[+] Example: ssh -R 8080:localhost:80 user@remote_host
	[+] Explanation: Forwards connections from port 8080 on the remote server to port 80 on your local machine.

	\033[1;35mDynamic Port Forwarding (SOCKS Proxy):\033[0m
	Usage: ssh -D <local_port> user@ssh_server
	[+] Example: ssh -D 1080 user@remote_host
	[+] Explanation: Creates a SOCKS proxy on local port 1080 that tunnels traffic through the SSH server.

	\033[1;36mNotes:\033[0m
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
