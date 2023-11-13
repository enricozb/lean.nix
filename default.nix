rec {
  lake2nix = import ./lake2nix.nix;

  mathlib = version:
    lake2nix {
      name = "mathlib";
      src = builtins.fetchGit {
        url = "git@github.com:leanprover-community/mathlib4";
        ref = "refs/tags/${version}";
      };
    };
}
