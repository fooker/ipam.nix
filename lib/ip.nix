lib:

with lib;

let
  mkAddress4 = mkAddress {
    version = 4;
    length = 4;

    toString = self: concatMapStringsSep "." toString self.data.raw;

    functor = mkAddress4;
  };

  mkAddress6 = mkAddress {
    version = 6;
    length = 16;

    toString = self:
      let
        # Words of the address as 8 elements of bytes with length 2
        words = genList
          (n: bytes.slice (n * 2) 2 self.data)
          ((self.data.length) / 2);

        # The longest span of consecutive zero words
        zeros = filter
          (span: all
            (word: word.raw == [ 0 0 ])
            (sublist span.start span.count words))
          (concatLists
            (genList
              (start: map
                (count: { inherit start count; })
                (range 2 (8 - start)))
              8));

        # Compressed words
        compressed =
          let
            span = last (sort
              (a: b:
                if a.count != b.count
                then a.count < b.count
                else a.start > b.start)
              zeros);
            fill =
              if span.start == 0 || (span.start + span.count) == 8
              then [ bytes.empty bytes.empty ]
              else [ bytes.empty ];
          in
          (take span.start words) ++ fill ++ (drop (span.start + span.count) words);

      in
      concatMapStringsSep ":"
        (part:
          if part.length > 0
          then toLower (toHexString (bytes.asInt part))
          else "")
        (if length zeros > 0 then compressed else words);

    functor = mkAddress6;
  };

  mkAddress =
    { version
    , length
    , toString
    , functor
    }: data:
      assert (assertMsg (data.length == length) "Address musst be ${toString length} bytes long");
      setType "ip.address" (fix (self: {
        inherit version length data functor;

        __toString = _: toString self;
      }));

  mkNetwork = address: prefixLength:
    assert (assertMsg (prefixLength >= 0 && prefixLength <= address.length * 8) "Prefix length must be >= 0 and <= ${address.length * 8}");
    setType "ip.network" (fix (self: {
      inherit address prefixLength;

      # The IP version
      version = self.address.version;

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
  address = rec {
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

    # Creates a network with this address and the given prefix length
    withPrefix = address:
      assert (assertMsg (isType "ip.address" address) "${toString network} is not address");
      mkNetwork address;

    # Creates a host network with this address and the maximal possible prefix length
    hostNetwork = address:
      assert (assertMsg (isType "ip.address" address) "${toString network} is not address");
      withPrefix address (address.length * 8);

    equals = a: b:
      assert (assertMsg (isType "ip.address" a) "${toString a} is not address");
      assert (assertMsg (isType "ip.address" b) "${toString b} is not address");
      a.data.raw == b.data.raw;
  };

  network = rec {
    parse = input:
      let
        split = splitString "/" input;
        address = lib.ip.address.parse (elemAt split 0);
        prefixLength = toInt (elemAt split 1);
      in
      assert (assertMsg ((length split) == 2) "'${input}' not in form <ip-address>/<prefix-length>");
      mkNetwork address prefixLength;

    # The network mask as bytes
    netmask = network:
      assert (assertMsg (isType "ip.network" network) "${toString network} is not network");
      bytes.fromBin (genList (n: n < network.prefixLength) (network.address.data.length * 8));

    # The prefix address of the network
    prefixAddress = network:
      assert (assertMsg (isType "ip.network" network) "${toString network} is not network");
      network.address.functor (bytes.and network.address.data (netmask network));

    # The prefix as a network with the host part set to zero
    prefixNetwork = network:
      assert (assertMsg (isType "ip.network" network) "${toString network} is not network");
      mkNetwork (prefixAddress network) network.prefixLength;

    equals = a: b:
      assert (assertMsg (isType "ip.network" a) "${toString a} is not network");
      assert (assertMsg (isType "ip.network" b) "${toString b} is not network");
      (ip.address.equals a.address b.address) && a.prefixLength == b.prefixLength;
  };
}
