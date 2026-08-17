-- Extra autostart processes.
o.launch_on_start("kanshi")
o.launch_on_start("alacritty --class main-terminal -e tmux new-session -A -s main")
