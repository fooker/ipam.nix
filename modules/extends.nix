{ lib, config, ... }:

with lib;

let
  mkExtend = name: mkOption {
    type = types.coercedTo (types.uniq types.anything) toList (types.listOf (types.uniq types.anything));
    description = ''
      Extensions options defined for elements of type ${name}
    '';
    default = { };
  };
in
{
  options = {
    extends = {
      site = mkExtend "site";
      prefix = mkExtend "prefix";
      route = mkExtend "route";
      reservation = mkExtend "reservation";
      address = mkExtend "address";
      device = mkExtend "device";
      interface = mkExtend "interface";
    };
  };

  config = {
    _module.args = {
      # TODO: Use types.optionType instead and leverage mkMerge to merge a custome module with the base definition
      extend = name: base:
        assert assertMsg (config.extends ? "${name}") "Undeclared extension: ${name}";
        types.submodule ([ base ] ++ config.extends."${name}");
    };
  };
}
