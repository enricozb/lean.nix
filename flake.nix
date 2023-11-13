{
  description = "nix utilities for lean4";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {
          overrides = (pkgs.callPackage ./overrides.nix { });

          lake2nix = params:
            (pkgs.callPackage ./lake2nix.nix { })
            ({ inherit overrides system; } // params);
        };
      });
}
