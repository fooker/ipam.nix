{ configuration
, lib
, check ? true
}:

with lib;

let
  # A lib with extensions
  extlib = lib.extend (import ./lib);

  eval = extlib.evalModules {
    modules = (toList configuration) ++ [
      ({ config, ... }: {
        config = {
          _module.check = check;
          _module.args = {
            ipam = config; # Re-expose global config into submodules
          };
        };

        options = {
          assertions = mkOption {
            type = types.listOf types.unspecified;
            internal = true;
            default = [ ];
            example = [{ assertion = false; message = "you can't enable this for that reason"; }];
            description = ''
              This option allows modules to express conditions that must
              hold for the evaluation of the system configuration to
              succeed, along with associated error messages for the user.
            '';
          };
        };
      })
    ] ++ (import ./modules);

    specialArgs = {
      modulesPath = builtins.toString ./modules;
    };
  };

  failedAssertions = filter (x: !x.assertion) eval.config.assertions;
in
if failedAssertions != [ ]
then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x.message}") failedAssertions)}"
else {
  inherit (eval) config options;
}
