java = "21"
"pipx:semgrep" = "latest"
"pip:flare-capa" = "latest"
ghidra = "latest"

[tasks.install-joern]
description = "Installs/Updates Joern to ~/.local/bin/joern-install"
run = """
#!/bin/bash
mkdir -p ~/.local/bin/joern-install
cd ~/.local/bin/joern-install
curl -L "https://github.com/joernio/joern/releases/latest/download/joern-install.sh" -o joern-install.sh
chmod +x joern-install.sh
./joern-install.sh --install-dir ~/.local/bin/joern-install
# Link the executable to a path mise sees (optional if you add this dir to path)
ln -sf ~/.local/bin/joern-install/joern ~/.local/share/mise/shims/joern
"""
