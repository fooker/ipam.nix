# IPAM for NixOS

A module definition for IP Address Management in Nix.
This modules provides a declarative approacht to IP Address Management using the nix language.

## Status

This is in a very early stage and not ready for production use.
The basic address assignement is working but most of the long-term goals are missing.

These goals include:
- [ ] Validation of assignments.
      This includes checking for duplicates, propper prefix and address consistency and valide site specifications.
- [ ] Reservations in prefixes with according checks.
- [ ] Sub-Prefixes with seperate sites and integrity checking.

## Usage

Declare your network by specifying a Sites, Devices, Interfaces and allocate Addresses in Prefixes by assigning them to devices.

`network.nix':
```nix
{
  sites = {
    "earth" = {};
    "mars" = {};
    "pluto" = {};
  };

  devices = {
    "dev1" = {
      type = "ACME PC";
      role = "Burrito";
      site = "earth"; # This must reference a declared site

      interfaces = {
        "wan" = {
          mac = "00:00:00:00:00:00";
        };
      };
    };
  };

  prefixes = {
    "1.2.3.0/24" = {
      site = "earth"; # This must reference a declared site

      gateway = "1.2.3.1";

      addresses = {
        "1.2.3.4" = {
          device = "dev1"; # This must reference an existing device
          interface = "wlan"; # This must reference an existing interface of the device
        };
      };
    };
  };
}
```

This network dclaration can be evaluated:
```
{ lib, name, ... }:
let
  network = import /ipam.nix/default.nix {
    inherit lib;
    configuration = ./network.nix;
  };

  # Name is the name of the current machine
  # Addopt according your method of deployment
  device = network.devices."${name}";

in {
  systemd.network = {
    links = mapAttrs'
      (name: iface: nameValuePair "00-${name}" {
        matchConfig = {
          MACAddress = iface.mac;
        };
        linkConfig = {
          Name = iface.name;
        };
      })
      device.interfaces;

    networks = mapAttrs'
      (name: iface: nameValuePair "30-${name}" {
        name = iface.name;
        address = map (addr: addr.addressWithPrefix) iface.addresses;
        gateway = map (addr: addr.gateway) iface.addresses;
        #dns = [ "172.23.200.129" ];
        #domains = [
        #  "home.open-desk.net"
        #  "priv.home.open-desk.net"
        #];
      })
      device.interfaces;
    };
  };
}