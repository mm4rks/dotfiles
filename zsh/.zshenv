# Ubuntu's /etc/zsh/zshrc runs a full, uncached compinit before ~/.zshrc,
# which then runs its own cached one. Skip the global call.
skip_global_compinit=1
