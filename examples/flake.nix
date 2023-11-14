{
  description = "some lean4 package";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.lean-nix.url = "github:enricozb/lean.nix";
  inputs.lean4.url = "github:leanprover/lean4/v4.3.0-rc1";
  inputs.lean-mathlib-src = {
    url = "github:leanprover-community/mathlib4/v4.3.0-rc1";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, lean-nix, lean4, lean-mathlib-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lean4-pkgs = lean4.packages.${system};
        lean-nix-pkgs = lean-nix.packages.${system};

        lean-mathlib = lean-nix-pkgs.lake2nix {
          name = "mathlib";
          src = lean-mathlib-src;
          lean-toolchain = lean4-pkgs;
        };

      in {
        devShells.default = pkgs.mkShell {
          packages = [
            lean4-pkgs.lean-all
            lean4-pkgs.vscode

            lean-mathlib.package.modRoot
          ];
        };
      });

}
