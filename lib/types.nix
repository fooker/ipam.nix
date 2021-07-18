lib:

with lib;

{
  # A type for references into an attrset.
  # The specified value will must be a string which is an existing key of the
  # given attrset `attrs`. The resulting value in the evaluated configuration
  # is the according value for the key in `attrs`.
  refAttr = attrs: mkOptionType rec {
    name = "refAttr";
    description = "a reference (one of ${concatMapStringsSep ", " (attrNames attrs)})";
    check = value: hasAttr value attrs;
    merge = loc: defs: getAttr (mergeEqualOption loc defs) attrs;
  };

  ip = rec {
    address = mkOptionType {
      name = "ipAddress";
      description = "IP Address";
      check = isType "ip.address";
      merge = mergeEqualOption;
    };

    address4 = types.addCheck address (x: x.version == 4);
    address6 = types.addCheck address (x: x.version == 6);

    strOrAddress = types.coercedTo types.str ip.address.parse address;
    strOrAddress4 = types.coercedTo types.str ip.address.parse address4;
    strOrAddress6 = types.coercedTo types.str ip.address.parse address6;

    network = mkOptionType {
      name = "ipNetwork";
      description = "IP Network";
      check = isType "ip.network";
      merge = mergeEqualOption;
    };

    network4 = types.addCheck network (x: x.version == 4);
    network6 = types.addCheck network (x: x.version == 6);

    strOrNetwork = types.coercedTo types.str ip.network.parse network;
    strOrNetwork4 = types.coercedTo types.str ip.network.parse network4;
    strOrNetwork6 = types.coercedTo types.str ip.network.parse network6;
  };
}
