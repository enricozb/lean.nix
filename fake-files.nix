# known fake files needed to build common lean4 packages
{ }:

{
  mathlib = {
    "Mathlib.Tactic.Widget.CommDiag" = [
      "widget/src/penrose/commutative.dsl"
      "widget/src/penrose/commutative.sty"
      "widget/src/penrose/triangle.sub"
      "widget/src/penrose/square.sub"
    ];
  };

  proofwidgets = {
    "ProofWidgets.Compat" = [ "build/js/compat.js" ];
    "ProofWidgets.Component.Basic" = [ "build/js/interactiveExpr.js" ];
    "ProofWidgets.Component.GoalTypePanel" = [ "build/js/goalTypePanel.js" ];
    "ProofWidgets.Component.Recharts" = [ "build/js/recharts.js" ];
    "ProofWidgets.Component.PenroseDiagram" = [ "build/js/penroseDisplay.js" ];
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
}
