{
  description = "NixOS configuration that automatically stows dotfiles";

  inputs = {
    # Nix Packages collection
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Your dotfiles flake, which provides your config files as a package
    # dotfiles = {
    #   url = "github:mm4rks/dotfiles";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # Define your NixOS system configuration
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; 
      modules = [
        ./configuration.nix
      ];
    };
  };
}


