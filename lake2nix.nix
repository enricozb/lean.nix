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
    overrides ? { },

    # dependencies to use in place of others.
    #
    # for a given dependency a in the dependency tree of a lean package, lake2nix
    # only builds it once. specifically it builds it the first time it encounters
    # it. for example, if a dependency tree for mathlib looks like this
    #
    #   - mathlib@v1.0.0:
    #     - std@v1.0.0
    #     - aesop@v1.0.0
    #       - std@v.0.5.0
    #
    # then std@v1.0.0 is used for all references of std, even the one under aesop.
    deps ? { },

    }@args:

    let
      # TODO: unclear if this is the correct approach. this works for mathlib (-> Mathlib)
      #       but proofwidgets -> Proofwidgets doesn't seem correct since the root is
      #       actually ProofWidgets
      #
      #       indeed this does fail fro proofwidgets. we should switch to an approach where
      #       we glob `src` for any `*.lean` whose file name without extension matches `name`
      #       up to casing. then we should use that as the package name.
      #
      #       in the meantime, `overrides` can provide a name for such packages.
      name = capitalize args.name;
      lower-name = lib.strings.toLower args.name;

      lean-toolchain = if args ? lean-toolchain then
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
          # TODO: this can be something like "nightly-2023-10-12", if this is the case, need to
          #       pull from this repo: https://github.com/leanprover/lean4-nightly instead, as
          #       it tags nightly versions.
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

          deps = (builtins.listToAttrs (builtins.map ({ git }: {
            name = git.name;
            value = git;
          }) lake-manifest.packages))
            // (if args ? deps then args.deps else { });

        in builtins.map (

          { git }:
          builtins.trace
          "building lean dep for ${args.name}: ${git.name} @ ${git.rev} using ${
            deps.${git.name}.rev
          }" (lake2nix {
            name = git.name;
            src = fetchDep deps.${git.name};
            inherit system lean-toolchain overrides deps;
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
