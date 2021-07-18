{ configuration
, lib
, check ? true
, extraSpecialArgs ? { }
}:

let
  # A lib with extensions
  extlib = lib.extend (import ./lib);

  eval = extlib.evalModules {
    modules = [
      configuration
      ({ config, ... }: {
        _module.check = check;
        _module.args = {
          ipam = config; # Re-expose global config
        };
      })
    ] ++ (import ./modules);

    specialArgs = {
      modulesPath = builtins.toString ./modules;
    } // extraSpecialArgs;
  };
in
{
  inherit (eval) config options;
}
