lib:

with builtins;
with lib;

let
  hex = stringToCharacters "0123456789abcdef";
  hex2dec = v: getAttr v (listToAttrs (imap0 (d: x: nameValuePair x d) hex));
  dec2hex = elemAt hex;

  mkBytes = raw: setType "bytes" {

    # The raw bytes
    inherit raw;

    # The number of bytes
    length = length raw;

    __toString = self: toString self.raw;
  };
in
rec {
  fromInt = int:
    assert (assertMsg (int >= 0) "Must be positive integer");
    let
      parse = i:
        if (i == 0)
        then [ ]
        else (parse (div i 256)) ++ (singleton (mod i 256));
    in
    mkBytes (parse int);

  fromDec = bytes:
    assert (assertMsg (all (b: 0 <= b && b <= 255) bytes) "Some bytes are not 0 <= x <= 255");
    mkBytes bytes;

  fromBin = bits:
    let
      bit = i: j: x: if elemAt bits (i * 8 + j) then x else 0;
    in
    assert (assertMsg ((mod (length bits) 8) == 0) "Bits must be multiple of 8");
    mkBytes (genList
      (i: (bit i 0 128)
        + (bit i 1 64)
        + (bit i 2 32)
        + (bit i 3 16)
        + (bit i 4 8)
        + (bit i 5 4)
        + (bit i 6 2)
        + (bit i 7 1)
      )
      ((length bits) / 8));

  parseHexString = s:
    let
      chars = stringToCharacters (toLower s);
      charAt = elemAt chars;
    in
    assert assertMsg (mod (length chars) 2 == 0) "Hex string length must be dividable by 2";
    mkBytes (genList
      (n: (hex2dec (charAt (n * 2 + 0))) * 16 + (hex2dec (charAt (n * 2 + 1))))
      ((length chars) / 2));

  concat = l:
    assert (assertMsg (all (isType "bytes") l) "All parts must by bytes");
    mkBytes (concatLists (map (l: l.raw) l));

  zipBytes = f: a: b:
    assert (assertMsg (isType "bytes" a) "${toString a} is not bytes");
    assert (assertMsg (isType "bytes" b) "${toString b} is not bytes");
    assert (assertMsg (a.length == b.length) "bytes differ in length");
    mkBytes (zipListsWith f a.raw b.raw);

  and = zipBytes bitAnd;
  or = zipBytes bitOr;

  empty = mkBytes [ ];

  # The bytes encoded as hex string
  asHexString = bytes:
    assert (assertMsg (isType "bytes" bytes) "${toString bytes} is not bytes");
    concatMapStrings
      (b: "${dec2hex (div b 16)}${dec2hex (mod b 16)}")
      bytes.raw;

  # Create a sub-slice of the bytes
  slice = start: count: bytes:
    assert (assertMsg (isType "bytes" bytes) "${toString bytes} is not bytes");
    mkBytes (sublist start count bytes.raw);

  # The bytes interpreted as an integer
  asInt = bytes:
    assert (assertMsg (isType "bytes" bytes) "${toString bytes} is not bytes");
    foldl (acc: val: acc * 256 + val) 0 bytes.raw;

  # Compare two bytes values
  equals = a: b:
    assert (assertMsg (isType "bytes" a) "${toString a} is not bytes");
    assert (assertMsg (isType "bytes" b) "${toString b} is not bytes");
    a.raw == b.raw;

  # Fill bytes with leading zeros
  fill = bytes: minLen:
    assert (assertMsg (isType "bytes" bytes) "${toString bytes} is not bytes");
    assert (assertMsg (bytes.length <= minLen) "${toString bytes} is longer than ${toString minLen}");
    mkBytes ((genList (_: 0) (minLen - bytes.length)) ++ bytes.raw);
}
