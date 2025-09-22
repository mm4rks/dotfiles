{
  description = "My dotfiles manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    # Supported systems
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    
    # Helper to provide nixpkgs for each system
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
      pkgs = import nixpkgs { inherit system; };
    });
  in
  {
    # home-manager module to be imported by the main NixOS flake
    homeManagerModules.default = { pkgs, ... }: {
      # This section manages packages and files in your home directory.

      # Stow is still used for your specific config files (.zshrc, nvim config, etc.)
      home.packages = [ 
        pkgs.stow 
      ];

      home.file.".dotfiles" = {
        source = self;
        recursive = true;
      };

      home.activation.stowDotfiles = pkgs.lib.hm.dag.entryAfter ["writeBoundary"] ''
        # This command re-links your dotfiles on every rebuild
        $DRY_RUN_CMD ${pkgs.stow}/bin/stow --restow --target=$HOME --dir=$HOME/.dotfiles */
      '';

      # -- NEW SECTION FOR ZSH PLUGINS --
      # Declaratively manage Zsh and its plugins
      programs.zsh = {
        enable = true; # Let home-manager manage the zsh environment
        plugins = [
          {
            name = "zsh-syntax-highlighting";
            src = pkgs.zsh-syntax-highlighting;
          }
          {
            name = "zsh-vi-mode";
            src = pkgs.zsh-vi-mode;
          }
        ];
      };

      # Enable fzf and its shell integrations (key bindings, etc.)
      programs.fzf = {
        enable = true;
      };
    };
  };
}


