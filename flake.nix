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
      home.packages = [ 
        # Stow is required to link the files
        pkgs.stow 
      ];

      # This creates a package from your dotfiles directory
      # and then runs a script to stow them into the home directory.
      home.file.".dotfiles" = {
        source = self;
        recursive = true;
      };

      # Activation script to run stow after a rebuild
      # It will stow every directory in your dotfiles repo.
      # Make sure your dotfiles are organized correctly for this.
      # Example: dotfiles/nvim/.config/nvim, dotfiles/zsh/.zshrc
      home.activation.stowDotfiles = pkgs.lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.stow}/bin/stow --restow --target=$HOME --dir=$HOME/.dotfiles */
      '';
    };
  };
}

