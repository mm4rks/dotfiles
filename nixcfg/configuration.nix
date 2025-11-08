# /etc/nixos/configuration.nix

{ config, pkgs, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.user = {
    isNormalUser = true;
    description = "User";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    shell = pkgs.zsh;
  };


  environment.systemPackages = with pkgs; [
    libgcc
    gcc
    ripgrep
    cmake
    unzip
    git
    wget
    curl
    tree
    stow
    neovim
    tmux

    firefox

    alacritty
    zsh
    fzf
    bat
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-vi-mode

    keepassxc
    signal-desktop
    obsidian
    nextcloud-client
    xfce.thunar
    pdfarranger
    zathura

    waybar
    rofi
    flameshot
    wl-clipboard
    pavucontrol
    pamixer
    hyprpaper
    hyprlock

    poppler-utils
    qpdf
  ];
  
  environment.variables.EDITOR = "nvim";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.wireguard.enable = true;
  time.timeZone = "europe/berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.enable = true;
  programs.hyprland.package = pkgs.hyprland;
  programs.hyprland.enable = true;
  services.greetd = {
      enable = true;
      settings = { 
          default_session = {
	      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd hyprland";
	      user = "greeter";
	  };
     };
  };
  programs.hyprlock.enable = true;
  programs.zsh.enable = true;
  programs.thunar.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true;
  };
  xdg.portal = {
    enable = true; extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
  nixpkgs.config.allowUnfree = true;
  hardware.graphics.enable = true;
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji font-awesome
    pkgs."nerd-fonts"."fira-mono"
  ];
  system.stateVersion = "23.11";
}


