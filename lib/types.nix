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

  ip = {
    address = types.coercedTo types.str ip.address.parse (mkOptionType {
      name = "ipAddress";
      description = "IP Address";
      check = isType "ip.address";
      merge = mergeEqualOption;
    });

    network = types.coercedTo types.str ip.network.parse (mkOptionType {
      name = "ipNetwork";
      description = "IP Network";
      check = isType "ip.network";
      merge = mergeEqualOption;
    });
  };
}
