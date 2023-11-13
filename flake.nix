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
          lake2nix = params:
            (pkgs.callPackage ./lake2nix.nix { })
            (params // { inherit system; });

          fake-files = (pkgs.callPackage ./fake-files.nix { });

          mathlib = rev:
            lake2nix {
              name = "mathlib";
              src = builtins.fetchGit {
                url = "git@github.com:leanprover-community/mathlib4";
                rev = rev;
              };

              inherit fake-files;
            };
        };
      });
}
