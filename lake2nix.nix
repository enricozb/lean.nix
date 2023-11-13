let

  stripNewline = str:
    let
      len = builtins.stringLength str;
      last_char = builtins.substring (len - 1) 1 str;
    in if last_char == "\n" then builtins.substring 0 (len - 1) str else str;

  fetchDep = dep:
    builtins.fetchGit {
      url = dep.url;
      rev = dep.rev;
      ref = dep."inputRev?";
    };

in { name, src, lake-manifest-file ? "${src}/lake-manifest.json"
, lean-toolchain ? null, lean-toolchain-file ? "${src}/lean-toolchain" }:
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
    })).packages.${builtins.currentSystem};

  # get deps from lake-manifest-file if it exists
  deps = if builtins.pathExists lake-manifest-file then
    let
      lake-manifest = builtins.fromJSON (builtins.readFile lake-manifest-file);

    in builtins.map ({ git }:
      lake2nix {
        name = git.name;
        src = fetchDep git;
        lean-toolchain = lean;
      }) lake-manifest.packages
  else
    [ ];

in lean.buildLeanPackage { inherit name src deps; }
