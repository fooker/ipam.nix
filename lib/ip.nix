lib:

with lib;

let
  mkAddress4 = mkAddress {
    version = 4;
    length = 4;

    toString = self: concatMapStringsSep "." toString self.bytes.bytes;

    functor = mkAddress4;
  };

  mkAddress6 = mkAddress {
    version = 6;
    length = 16;

    toString = self:
      let
        parts = genList
          (n: self.bytes.slice (n * 2) 2)
          ((self.bytes.length) / 2);

      in
      concatMapStringsSep ":"
        (part: toLower (toHexString part.asInt))
        parts;

    functor = mkAddress6;
  };

  mkAddress =
    { version
    , length
    , toString
    , functor
    }: bytes:
      assert (assertMsg (bytes.length == length) "Address musst be ${toString length} bytes long");
      setType "ip.address" {
        inherit version bytes functor;

        __toString = toString;
      };

  mkNetwork = address: prefixLength:
    setType "ip.network" (fix (self: {
      inherit address prefixLength;

      # The IP version
      version = self.address.version;

      # The network mask as bytes
      netmask = bytes.fromBin (genList (n: n < self.prefixLength) (self.address.bytes.length * 8));

      # The prefix network
      network = self.address.functor (bytes.and self.address.bytes self.netmask);

      __toString = self: "${toString self.address}/${toString self.prefixLength}";
    }));

  parseAddress4 = input:
    let
      parts = splitString "." input;
    in
    mkAddress4 (bytes.fromDec (map toInt parts));

  parseAddress6 = input:
    let
      parts = splitString ":" input;
      normalized = replaceStrings
        [ "::" ]
        [ (concatStrings (genList (const ":") (10 - (length parts)))) ]
        input;
    in
    mkAddress6 (bytes.concat (map
      (part: bytes.parseHexString (fixedWidthString 4 "0" part))
      (splitString ":" normalized)));
in
{
  address = {
    parse = input:
      let
        len4 = length (splitString "." input);
        len6 = length (splitString ":" input);
      in
      if 3 <= len6 && len6 <= 8 then
        parseAddress6 input
      else if len4 == 4 then
        parseAddress4 input
      else throw "'${input}' is not a valid address";
  };

  network = {
    parse = input:
      let
        split = splitString "/" input;
        address = lib.ip.address.parse (elemAt split 0);
        prefixLength = toInt (elemAt split 1);
      in
      assert (assertMsg ((length split) == 2) "'${input}' not in form <ip-address>/<prefix-length>");
      mkNetwork address prefixLength;
  };
}
