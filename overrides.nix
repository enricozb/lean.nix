# known fake files needed to build common lean4 packages
{ pkgs }:

rec {
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

  mathlib = {
    overrideBuildModAttrs = addFakeFiles {
      "Mathlib.Tactic.Widget.CommDiag" = [
        "widget/src/penrose/commutative.dsl"
        "widget/src/penrose/commutative.sty"
        "widget/src/penrose/triangle.sub"
        "widget/src/penrose/square.sub"
      ];
    };
  };

  proofwidgets = {
    overrideBuildModAttrs = addFakeFiles {
      "ProofWidgets.Compat" = [ "build/js/compat.js" ];
      "ProofWidgets.Component.Basic" = [ "build/js/interactiveExpr.js" ];
      "ProofWidgets.Component.GoalTypePanel" = [ "build/js/goalTypePanel.js" ];
      "ProofWidgets.Component.Recharts" = [ "build/js/recharts.js" ];
      "ProofWidgets.Component.PenroseDiagram" =
        [ "build/js/penroseDisplay.js" ];
      "ProofWidgets.Component.Panel.SelectionPanel" =
        [ "build/js/presentSelection.js" ];
      "ProofWidgets.Component.Panel.GoalTypePanel" =
        [ "build/js/goalTypePanel.js" ];
      "ProofWidgets.Component.MakeEditLink" = [ "build/js/makeEditLink.js" ];
      "ProofWidgets.Component.OfRpcMethod" = [ "build/js/ofRpcMethod.js" ];
      "ProofWidgets.Component.HtmlDisplay" =
        [ "build/js/htmlDisplay.js" "build/js/htmlDisplayPanel.js" ];
      "ProofWidgets.Presentation.Expr" = [ "build/js/exprPresentation.js" ];
    };
  };
}
