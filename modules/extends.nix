{ lib, config, ... }:

with lib;

let
  mkExtend = type: mkOption {
    type = types.attrsOf (types.submodule ({ name, config, ... }: {
      options = {
        type = mkOption {
          type = types.optionType;
          description = ''
            Type of the extionsion option.
          '';
        };
        description = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Description of the extension option.
          '';
        };
        default = mkOption {
          type = types.nullOr config.type;
          default = null;
          description = ''
            Default value for the extension option.
          '';
        };
      };
    }));
    description = ''
      Extensions options defined for elements of type ${type}
    '';
    default = { };
  };

  mkOptions = type: mapAttrs
    (name: option: mkOption {
      inherit (option) type description default;
    })
    config.extends.${type};
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
        types.submodule [
          base
          { options = mkOptions name; }
        ];
    };
  };
}
