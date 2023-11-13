rec {
  lake2nix =
    (import ../default.nix).packages.${builtins.currentSystem}.lake2nix;

  mathlib = lake2nix {
    name = "mathlib";
    src = builtins.fetchGit {
      url = "git@github.com:leanprover-community/mathlib4";
    };
  };
}
