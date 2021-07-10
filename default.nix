{ configuration
, pkgs
, lib ? pkgs.lib
, check ? true
,  extraSpecialArgs ? { }
}:

with lib;

let
  modules = import ./modules;

  eval = evalModules {
    inherit check;

    modules = [ configuration ] ++ modules;
    
    specialArgs = {
      modulesPath = builtins.toString ./modules;
    } // extraSpecialArgs;
  };
in
  {
    inherit (eval) config options;
  }