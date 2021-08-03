{ config, lib, ipam, ... }:

with lib;

let
  site = { config, name, ... }: {
    options = with types; {
      name = mkOption {
        type = str;
        description = ''
          A unique name for the size.
        '';
        readOnly = true;
        default = name;
      };

      region = mkOption {
        type = nullOr str;
        description = ''
          The geographical region of the site.
        '';
        default = null;
      };

      devices = mkOption {
        type = listOf unspecified;
        description = ''
          All devices in this site.
        '';
        readOnly = true;
      };

      prefixes = mkOption {
        type = listOf unspecified;
        description = ''
          All prefixes in this site.
        '';
        readOnly = true;
      };
    };

    config = {
      devices = filter
        (device: device.site.name == config.name)
        (attrValues ipam.devices);

      prefixes = filter
        (prefix: prefix.site.name == config.name)
        (attrValues ipam.prefixes);
    };
  };

  device = { config, name, ... }: {
    options = with types; {
      name = mkOption {
        type = str;
        description = ''
          A unique name for the device.
        '';
        readOnly = true;
        default = name;
      };

      type = mkOption {
        type = str;
        description = ''
          Model information for the device.
        '';
      };

      role = mkOption {
        type = str;
        description = ''
          Functional role of the device.
        '';
        example = "Core Switch";
      };

      serial = mkOption {
        type = nullOr str;
        description = ''
          Serial number of the device.
        '';
        default = null;
      };

      asset_id = mkOption {
        type = nullOr str;
        description = ''
          A unique ID used to identifiy the device.
        '';
        default = null;
      };

      site = mkOption {
        type = nullOr (refAttr ipam.sites);
        description = ''
          The site the device is located in.
        '';
      };

      status = mkOption {
        type = enum [ "active" "planned" "decommissioning" ];
        description = ''
          The service status of the device.
        '';
        default = "active";
      };

      comments = mkOption {
        type = lines;
        description = ''
          Commentary notes for the device.
        '';
        default = "";
      };

      interfaces = mkOption {
        type = attrsOf (submodule (interface config));
        description = ''
          The interfaces of the device.
        '';
        default = { };
      };
    };
  };

  interface = device: { config, name, ... }: {
    options = with types; {
      name = mkOption {
        type = str;
        description = ''
          The name of the interface.
        '';
        readOnly = true;
        default = name;
      };

      device = mkOption {
        type = unspecified;
        description = ''
          The device the interface is defined on.
        '';
        readOnly = true;
        default = device;
      };

      mac = mkOption {
        type = nullOr (strMatching "^([0-9a-f]{2}:){5}([0-9a-f]{2})$");
        description = ''
          MAC address of the interface.
        '';
        default = null;
      };

      addresses = mkOption {
        type = listOf unspecified;
        description = ''
          The IP addresses assigned to the interface.
        '';
        readOnly = true;
      };

      satelite = mkOption {
        type = nullOr (submodule {
          options = {
            addresses = mkOption {
              type = listOf ip.network;
              description = ''
                IP addresses of the satelite interface.
              '';
            };

            gateways = mkOption {
              type = listOf ip.address;
              description = ''
                IP addresses of gateways for the satelite interface.
              '';
            };

            dns = mkOption {
              type = listOf ip.address;
              description = ''
                IP addresses of DNS server for the satelite interface.
              '';
            };
          };
        });
        description = ''
          A satelite interface definition.

          A satelite interface is not associated to any managed prefix but has a
          standalone address configuration directly assigned to the interface.
        '';
        default = null;
      };
    };

    config = {
      addresses = filter
        (address: address.device.name == device.name && address.interface.name == config.name)
        (concatMap
          (prefix: (attrValues prefix.addresses))
          (attrValues ipam.prefixes));
    };
  };
in
{
  options = with types; {
    sites = mkOption {
      type = attrsOf (submodule site);
      description = ''
        The sites of your network.
      '';
      default = { };
    };

    devices = mkOption {
      type = attrsOf (submodule device);
      description = ''
        Pieces of hardware.
      '';
      default = { };
    };
  };

  config.assertions = flatten [
    (map
      (device:
        (map
          (interface: {
            assertion = interface.satelite != null -> interface.addresses == [ ];
            message = "${device}:${interface} has satelite config but also assigned addresses";
          })
          (attrValues device.interfaces))
      )
      (attrValues config.devices))
  ];
}
