lib:

with lib;

{
  ensureSingle = pred: findSingle
    pred
    (throw "No element found")
    (throw "More than one element found");
}
