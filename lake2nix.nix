{ lib }:

let
  stripNewline = str:
    let
      len = builtins.stringLength str;
      last_char = builtins.substring (len - 1) 1 str;
    in if last_char == "\n" then builtins.substring 0 (len - 1) str else str;

  capitalize = str:
    let
      first = builtins.substring 0 1 str;
      rest = builtins.substring 1 (builtins.stringLength str - 1) str;
    in (lib.strings.toUpper first) + rest;

  fetchDep = dep:
    builtins.fetchGit {
      url = dep.url;
      rev = dep.rev;
      ref = dep."inputRev?";
    };

  lake2nix = {
    # the name of the lake package being built
    name,
    # the package source
    src,
    # the nix system being built for
    system ? builtins.currentSystem,
    # an object containing the `buildLeanPackage` function
    lean-toolchain ? null,
    # a path to the `lake-manifest.json` file
    lake-manifest-file ? "${src}/lake-manifest.json",
    # path to the `lean-toolchain` file
    lean-toolchain-file ? "${src}/lean-toolchain" }:

    let
      lean = if !(builtins.isNull lean-toolchain) then
        lean-toolchain
      else
        let
          # "leanprover/lean4:v4.2.0-rc1"
          string = stripNewline (builtins.readFile lean-toolchain-file);
          # [ "leanprover/lean4" "v4.2.0-rc1" ]
          parts = builtins.filter builtins.isString (builtins.split ":" string);
          # "leanprover/lean4"
          repo = builtins.elemAt parts 0;
          # "v4.2.0-rc1"
          ref = builtins.elemAt parts 1;
        in (import (builtins.fetchGit {
          # TODO: should github be hardcoded?
          url = "git@github.com:${repo}";
          ref = "refs/tags/${ref}";
          # TODO: need a hash here or else this won't be pure
        })).packages.${builtins.currentSystem};

      # get deps from lake-manifest-file if it exists
      deps = if builtins.pathExists lake-manifest-file then
        let
          lake-manifest =
            builtins.fromJSON (builtins.readFile lake-manifest-file);

        in builtins.map (

          { git }:
          (lake2nix {
            name = git.name;
            src = fetchDep git;
            system = system;
            lean-toolchain = lean;
          }).package

        ) lake-manifest.packages
      else
        [ ];

    in {
      inherit lean;
      package = lean.buildLeanPackage {
        name = capitalize name;
        inherit src deps;
      };
    };

in lake2nix
