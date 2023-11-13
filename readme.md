# Lean.nix

> [!WARNING]
> This is still under development and should not be used for anything serious yet.

Some utilities to simplify using lean with nix.

## Example Usage
Inside of some `flake.nix`:
```nix
{
  description = "some lean 4 project";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.lean-nix.url = "github:enricozb/lean.nix";
  inputs.lean4.url = "github:leanprover/lean4/v4.2.0";
  inputs.lean-mathlib-src = {
    url = "github:leanprover-community/mathlib4/v4.2.0";
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
            lean-mathlib.lean-toolchain.lean
            lean-mathlib.lean-toolchain.vscode
            lean-mathlib.package.modRoot
          ];
        };
      });
}
```

> [!NOTE]
> In order for the derivation to be pure, you must provide a `lean-toolchain` to `lake2nix`.
> If you don't `lake2nix` will use the toolchain specified in the `${src}/lean-toolchain` file,
> which will be an impure `fetchGit` operation.

The output of `lake2nix` contains two attributes:
- `lean-toolchain`: the lean toolchain used to build this package.
  - if `lean-toolchain` was provided to `lake2nix`, this is that same value.
- `package`: this is the result of [`buildLeanPackage`][1].


## Details
`lake2nix` will read from `lean-toolchain`, and `lake-manifest.json` to determine the lean version
and the dependencies that need to be built. `lake-manifest.json` containing `rev` for each of the
dependencies allows `lake2nix` to be pure.


[1]: https://github.com/leanprover/lean4/blob/master/nix/buildLeanPackage.nix
[2]: https://github.com/leanprover/lean4/tree/master/src/lake
[3]: https://github.com/leanprover-community/mathlib4
