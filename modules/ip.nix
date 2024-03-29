{ config, lib, ipam, extend, ... }:

with lib;

let
  address = prefix: extend "address" ({ config, name, ... }: {
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
  });

  route = prefix: extend "route" ({ config, ... }: {
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
  });

  reservation = prefix: extend "reservation" ({ name, ... }: {
    options = with types; {
      name = mkOption {
        type = str;
        description = ''
          The name of the reservation.
        '';
        readOnly = true;
        default = name;
      };

      description = mkOption {
        type = str;
        description = ''
          Description for the reservation.
        '';
      };

      range = mkOption {
        type = addCheck (listOf ip.address) (l: (length l) == 2);
        description = ''
          Reserved range as start and end address (both inclusive).
        '';
      };

      prefix = mkOption {
        type = unspecified;
        description = ''
          The prefix this reservation is assigned to.
        '';
        readOnly = true;
        default = prefix;
      };
    };
  });

  prefix = extend "prefix" ({ config, name, ... }: {
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
        type = attrsOf (address config);
        description = ''
          Addresses assigned in this prefix.
        '';
        default = { };
      };

      routes = mkOption {
        type = listOf (route config);
        description = ''
          Additional routes available in this prefix.
        '';
        default = [ ];
      };

      reservations = mkOption {
        type = attrsOf (reservation config);
        description = ''
          Reserved addresses in this prefix.
        '';
        default = { };
      };
    };
  });
in
{
  options = with types; {
    prefixes = mkOption {
      type = attrsOf prefix;
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
