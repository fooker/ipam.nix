{ lib, ipam, ... }:

with lib;

let
  address = prefix: { config, name, ... }: {
    options = with types; {
      address = mkOption {
        type = ip.address;
        description = ''
          The address.
        '';
        readOnly = true;
        default = name;
      };

      prefix = mkOption {
        type = unspecified;
        description = ''
          The prefix this address is assigned to.
        '';
        readOnly = true;
        default = prefix;
      };

      addressWithPrefix = mkOption {
        type = str;
        description = ''
          The address with the prefix length of the assigned prefix in CIDR notation.
        '';
        readOnly = true;
        default = "${toString config.address}/${toString config.prefix.prefix.prefixLength}";
      };

      device = mkOption {
        type = refAttr ipam.devices;
        description = ''
          The device this address is assigned to.
        '';
      };

      interface = mkOption {
        type = refAttr config.device.interfaces;
        description = ''
          The interface this address is assigned to.
        '';
      };

      gateway = mkOption {
        type = nullOr ip.address;
        description = ''
          The gateway to use by this address.
        '';
        default = config.prefix.gateway;
      };
    };
  };

  prefix = { config, name, ... }: {
    options = with types; {
      prefix = mkOption {
        type = ip.network;
        description = ''
          IPv4 or IPv6 network with mask in CIDR notation.
        '';
        readOnly = true;
        default = name;
      };

      site = mkOption {
        type = nullOr (refAttr ipam.sites);
        description = ''
          Site the prefix is assigned to.
        '';
      };

      gateway = mkOption {
        type = nullOr ip.address;
        description = ''
          The gateway used in this prefix.
        '';
        default = null;
      };

      addresses = mkOption {
        type = attrsOf (submodule (address config));
        description = ''
          Addresses assigned in this prefix.
        '';
        default = { };
      };
    };
  };
in
{
  options = with types; {
    prefixes = mkOption {
      type = attrsOf (submodule prefix);
      description = ''
        Prefixes.
      '';
      default = { };
    };
  };
}
