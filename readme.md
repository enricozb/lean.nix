# Lean.nix

> [!WARNING]
> This is still under development and should not be used for anything serious yet.

Some utilities to simplify using lean with nix.

## Usages
`default.nix` provides a few attributes:
- `lake2nix` which lets you build an arbitrary lean package managed by [lake][1].
- `mathlib` a function that takes in a `version` and builds that version of [mathlib][2].

## Info
*this section needs to be cleaned up*
- Use `lean-toolchain` to know which version of `lean4` to pull.
- Use `lakefile.lean` to pull the right inputs.

## TODO
- this should be a `flake.nix`

[1]: https://github.com/leanprover/lean4/tree/master/src/lake
[2]: https://github.com/leanprover-community/mathlib4
