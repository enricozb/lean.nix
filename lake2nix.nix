{ pkgs, lib }:

let
  capitalize = str:
    let
      first = builtins.substring 0 1 str;
      rest = builtins.substring 1 (builtins.stringLength str - 1) str;
    in (lib.strings.toUpper first) + rest;

  fetchDep = dep:
    builtins.fetchGit {
      url = dep.url;
      rev = dep.rev;
      # ref = dep."inputRev?";
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
    lean-toolchain-file ? "${src}/lean-toolchain",

    # a map of overrides to provide to buildLeanPackage for specific packages.
    # the top-level keys for this attrset represent the packages and MUST be in lower case
    # for example:
    #   mathlib = {
    #     overrideBuildModAttrs = addFakeFiles {
    #       "Mathlib.Tactic.Widget.CommDiag" = [
    #         "widget/src/penrose/commutative.dsl"
    #         "widget/src/penrose/commutative.sty"
    #         "widget/src/penrose/triangle.sub"
    #         "widget/src/penrose/square.sub"
    #       ];
    #     }
    #   }
    overrides ? { }, }@args:

    let
      # TODO: unclear if this is the correct approach. this works for mathlib (-> Mathlib)
      #       but proofwidgets -> Proofwidgets doesn't seem correct since the root is
      #       actually ProofWidgets
      name = capitalize args.name;
      lower-name = lib.strings.toLower args.name;

      lean-toolchain = if !(builtins.isNull args.lean-toolchain) then
        args.lean-toolchain
      else
        let
          # "leanprover/lean4:v4.2.0-rc1"
          string = lib.strings.removeSuffix "\n"
            (builtins.readFile lean-toolchain-file);
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
          # TODO: need a hash here or else this won't be pure.
          #       maybe purity will only be possible if lean-toolchain is provided.
        })).packages.${builtins.currentSystem};

      # get deps from lake-manifest-file if it exists
      deps = if builtins.pathExists lake-manifest-file then
        let
          lake-manifest =
            builtins.fromJSON (builtins.readFile lake-manifest-file);

        in builtins.map (

          { git }:
          builtins.trace "building lean dep: ${git.name}" (lake2nix {
            name = git.name;
            src = fetchDep git;
            inherit system lean-toolchain fake-files;
          }).package

        ) lake-manifest.packages
      else
        [ ];

      buildLeanPackageArgs = {
        inherit name src;
      } // (if deps == [ ] then { } else { inherit deps; })
        // (if overrides ? ${lower-name} then overrides.${lower-name} else { });

    in {
      inherit lean-toolchain;

      package = lean-toolchain.buildLeanPackage buildLeanPackageArgs;
    };

in lake2nix
