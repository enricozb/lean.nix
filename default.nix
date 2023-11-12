let
  lake2nix = { name, src, lake-manifest-file ? "${src}/lake-manifest.json"
    , lean-toolchain ? null, lean-toolchain-file ? "${src}/lean-toolchain" }:
    let
      lean = if !(builtins.isNull lean-toolchain) then
        lean-toolchain
      else
        let
          # "leanprover/lean4:v4.2.0-rc1"
          string = builtins.readFile lean-toolchain-file;
          # [ "leanprover/lean4" "v4.2.0-rc1" ]
          parts = builtins.filter builtins.isString (builtins.split ":" string);
          # "leanprover/lean4"
          repo = builtins.elemAt parts 0;
          # "v4.2.0-rc1"
          rev = builtins.elemAt parts 1;
        in import (builtins.fetchGit {
          # TODO: should github be hardcoded?
          url = "git@github.com:${repo}";
          rev = rev;
        });

      # get deps from lake-manifest-file if it exists
      deps = if builtins.pathExists lake-manifest-file then
        let
          lake-manifest =
            builtins.fromJSON (builtins.readFile lake-manifest-file);

          fetchDep = { url, rev, ... }@dep:
            builtins.fetchGit {
              inherit url rev;
              ref = dep."inputRev?";
            };

        in builtins.map ({ git }:
          lake2nix {
            name = git.name;
            src = fetchDep git;
          }) lake-manifest.packages
      else
        [ ];

    in lean.buildLeanPackage {
      inherit name src deps;
      lean-toolchain = lean;
    };
in lake2nix
