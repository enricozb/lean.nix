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

  # from: https://github.com/nomeata/loogle/blob/6e49f2b0d96ccc093c87dbc963819ece51e7b582/flake.nix#L44-L83
  # addFakeFile can plug into buildLeanPackage’s overrideBuildModAttrs
  # it takes a lean module name and a filename, and makes that file available
  # (as an empty file) in the build tree, e.g. for include_str.
  # this is necessary for Mathlib, ProofWidgets, and maybe others.
  addFakeFiles = m: self: super:
    if m ? ${super.name} then
      let paths = m.${super.name};
      in {
        src = pkgs.runCommandCC "${super.name}-patched" {
          inherit (super) leanPath src relpath;
        } (''
          dir=$(dirname $relpath)
          mkdir -p $out/$dir
          if [ -d $src ]; then cp -r $src/. $out/$dir/; else cp $src $out/$leanPath; fi
        '' + pkgs.lib.concatMapStringsSep "\n" (p: ''
          install -D -m 644 ${pkgs.emptyFile} $out/${p}
        '') paths);
      }
    else
      { };

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

    # a map of fake files to add for lean packages with a given name.
    # the top-level keys for this attrset need to be in lower case
    # for example:
    #   fake-files = {
    #     mathlib = {
    #       "Mathlib.Tactic.Widget.CommDiag" = [
    #         "widget/src/penrose/commutative.dsl"
    #         "widget/src/penrose/commutative.sty"
    #         "widget/src/penrose/triangle.sub"
    #         "widget/src/penrose/square.sub"
    #       ];
    #     }
    #   }
    fake-files ? { }, }@args:

    let
      # TODO: unclear if this is the correct approach. this works for mathlib (-> Mathlib)
      #       but proofwidgets -> Proofwidgets doesn't seem correct since the root is
      #       actually ProofWidgets
      name = capitalize args.name;
      lower-name = lib.strings.toLower args.name;

      lean = if !(builtins.isNull lean-toolchain) then
        lean-toolchain
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
            system = system;
            lean-toolchain = lean;
          }).package

        ) lake-manifest.packages
      else
        [ ];

    in {
      inherit lean;
      package = lean.buildLeanPackage ({
        inherit name src;
      } // (if deps == [ ] then { } else { inherit deps; })
        // (if fake-files ? ${lower-name} then
          builtins.trace "adding fake files for dep: ${lower-name}" {
            overrideBuildModAttrs = addFakeFiles fake-files.${lower-name};
          }
        else
          { }));
    };

in lake2nix
