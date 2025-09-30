{
  description = "My dotfiles, exposed as a simple package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    # The simplest output: just provide the source code of this repo
    # as the default package.
    packages.x86_64-linux.default = self;
  };
}

