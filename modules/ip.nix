{ config, lib, ipam, ... }:

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

      withPrefix = mkOption {
        type = unspecified;
        description = ''
          The address associated to the containing prefix.
        '';
        readOnly = true;
        default = lib.ip.address.withPrefix config.address config.prefix.prefixLength;
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

  route = prefix: { config, ... }: {
    options = with types; {
      destination = mkOption {
        type = ip.network;
        description = ''
          The destination prefix of the route.
        '';
      };

      gateway = mkOption {
        type = ip.address;
        description = ''
          The gateway address.
        '';
        default = config.prefix.gateway;
      };

      prefix = mkOption {
        type = unspecified;
        description = ''
          The prefix this address is assigned to.
        '';
        readOnly = true;
        default = prefix;
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

      prefixLength = mkOption {
        type = int;
        description = ''
          Prefix length of this prefix.
        '';
        readOnly = true;
        default = config.prefix.prefixLength;
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

      dns = mkOption {
        type = listOf ip.address;
        description = ''
          The DNS servers to use for this prefix.
        '';
        default = [ ];
      };

      addresses = mkOption {
        type = attrsOf (submodule (address config));
        description = ''
          Addresses assigned in this prefix.
        '';
        default = { };
      };

      routes = mkOption {
        type = listOf (submodule (route config));
        description = ''
          Additional routes available in this prefix.
        '';
        default = [ ];
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

  config.assertions = flatten [
    (map
      (prefix: {
        assertion = ip.network.equals prefix.prefix (ip.network.prefixNetwork prefix.prefix);
        message = "Prefix ${toString prefix.prefix} is not a pure network prefix (host-part is not all-zero)";
      })
      (attrValues config.prefixes))

    (map
      (prefix:
        (map
          (address: {
            assertion = ip.network.equals (ip.network.prefixNetwork address.withPrefix) address.prefix.prefix;
            message = "Address ${toString address.address} is outside of ${toString address.prefix.prefix}";
          })
          (attrValues prefix.addresses))
      )
      (attrValues config.prefixes))
  ];
}
