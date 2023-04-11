# to run these tests:
# nix-instantiate --eval --strict -E 'import ./lib/tests.nix {}' --show-trace
# if the resulting list is empty, all tests passed

{ lib ? (import <nixpkgs> { }).lib }:

with lib.extend (import ./default.nix);

runTests {
  # bytes.nix

  testBytesFromIntZero = {
    expr = (bytes.fromInt 0).raw;
    expected = [ ];
  };

  testBytesFromIntShort = {
    expr = (bytes.fromInt 129).raw;
    expected = [ 129 ];
  };

  testBytesFromIntLong = {
    expr = (bytes.fromInt 13372342).raw;
    expected = [ 204 11 182 ];
  };

  testBytesFromDecEmpty = {
    expr = (bytes.fromDec [ ]).raw;
    expected = [ ];
  };

  testBytesFromDecShort = {
    expr = (bytes.fromDec [ 42 ]).raw;
    expected = [ 42 ];
  };

  testBytesFromDecLong = {
    expr = (bytes.fromDec [ 42 23 0 255 1 ]).raw;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesFromBinEmpty = {
    expr = (bytes.fromBin [ ]).raw;
    expected = [ ];
  };

  testBytesFromBinShort = {
    expr = (bytes.fromBin [ false false true false true false true false ]).raw;
    expected = [ 42 ];
  };

  testBytesFromBinLong = {
    expr = (bytes.fromBin (concatLists [
      [ false false true false true false true false ]
      [ false false false true false true true true ]
      [ false false false false false false false false ]
      [ true true true true true true true true ]
      [ false false false false false false false true ]
    ])).raw;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesParseHexStringEmpty = {
    expr = (bytes.parseHexString "").raw;
    expected = [ ];
  };

  testBytesParseHexStringShort = {
    expr = (bytes.parseHexString "2a").raw;
    expected = [ 42 ];
  };

  testBytesParseHexStringLong = {
    expr = (bytes.parseHexString "2a1700ff01").raw;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesParseHexStringCased = {
    expr = (bytes.parseHexString "2A1700Ff01").raw;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesAsHexStringEmpty = {
    expr = bytes.asHexString (bytes.fromDec [ ]);
    expected = "";
  };

  testBytesAsHexStringLong = {
    expr = bytes.asHexString (bytes.fromDec [ 42 23 0 255 1 ]);
    expected = "2a1700ff01";
  };

  testBytesAsIntEmpty = {
    expr = bytes.asInt (bytes.fromDec [ ]);
    expected = 0;
  };

  testBytesAsIntShort = {
    expr = bytes.asInt (bytes.fromDec [ 254 128 ]);
    expected = 65152;
  };

  testBytesAsIntLong = {
    expr = bytes.asInt (bytes.fromDec [ 42 23 0 255 ]);
    expected = 706150655;
  };

  testBytesSlice = {
    expr = (bytes.slice 1 3 (bytes.fromDec [ 42 23 0 255 1 ])).raw;
    expected = [ 23 0 255 ];
  };

  testBytesLength = {
    expr = (bytes.fromDec [ 42 23 0 255 1 ]).length;
    expected = 5;
  };

  testBytesConcat = {
    expr = (bytes.concat [
      (bytes.fromDec [ ])
      (bytes.fromDec [ 42 23 ])
      (bytes.fromDec [ ])
      (bytes.fromDec [ 0 255 1 ])
      (bytes.fromDec [ ])
    ]).raw;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesEquals = {
    expr = bytes.equals
      (bytes.fromDec [ 13 37 23 42 ])
      (bytes.fromDec [ 13 37 23 42 ]);
    expected = true;
  };

  testBytesFill = {
    expr = (bytes.fill (bytes.fromDec [ 13 37 23 42 ]) 8).raw;
    expected = [ 0 0 0 0 13 37 23 42 ];
  };

  testBytesFillEmpty = {
    expr = (bytes.fill (bytes.fromDec [ ]) 3).raw;
    expected = [ 0 0 0 ];
  };

  testBytesFillFull = {
    expr = (bytes.fill (bytes.fromDec [ 13 37 23 42 ]) 4).raw;
    expected = [ 13 37 23 42 ];
  };

  # ip.nix

  testIpAddressParse4 = {
    expr = (ip.address.parse "1.2.3.4").data.raw;
    expected = [ 1 2 3 4 ];
  };

  testIpAddressParse6Full = {
    expr = (ip.address.parse "fe80:0:0:0:0:0:0:0").data.raw;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpAddressParse6Sparse = {
    expr = (ip.address.parse "fe80::0").data.raw;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpAddressParse6MinimalPrefix = {
    expr = (ip.address.parse "fe80::").data.raw;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpAddressParse6MinimalSuffix = {
    expr = (ip.address.parse "::1").data.raw;
    expected = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 ];
  };

  testIpAddressParse6MinimalZero = {
    expr = (ip.address.parse "::").data.raw;
    expected = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpAddressType4 = {
    expr = isType "ip.address" (ip.address.parse "1.2.3.4");
    expected = true;
  };

  testIpAddressType6 = {
    expr = isType "ip.address" (ip.address.parse "::1");
    expected = true;
  };

  testIpAddressToString4 = {
    expr = toString (ip.address.parse "1.2.3.4");
    expected = "1.2.3.4";
  };

  testIpAddressToString6Full = {
    expr = toString (ip.address.parse "fe80:1:808:42:1:1:ffff:2");
    expected = "fe80:1:808:42:1:1:ffff:2";
  };

  testIpAddressToString6CompressedNone = {
    expr = toString (ip.address.parse "fe80:0:808:42:1:1:ffff:0");
    expected = "fe80:0:808:42:1:1:ffff:0";
  };

  testIpAddressToString6CompressedSuffix = {
    expr = toString (ip.address.parse "fe80::");
    expected = "fe80::";
  };

  testIpAddressToString6CompressedPrefix = {
    expr = toString (ip.address.parse "::1");
    expected = "::1";
  };

  testIpAddressToString6CompressedInfix = {
    expr = toString (ip.address.parse "fe80::1");
    expected = "fe80::1";
  };

  testIpAddressToString6CompressedMulti = {
    expr = toString (ip.address.parse "fe80:0:0:1::1");
    expected = "fe80:0:0:1::1";
  };

  testIpAddressToString6CompressedMultiFirst = {
    expr = toString (ip.address.parse "fe80:0:0:1:1:0:0:1");
    expected = "fe80::1:1:0:0:1";
  };

  testIpNetworkParse4Address = {
    expr = (ip.network.parse "1.2.3.4/18").address.data.raw;
    expected = [ 1 2 3 4 ];
  };

  testIpNetworkParse4Prefix = {
    expr = (ip.network.parse "1.2.3.4/18").prefixLength;
    expected = 18;
  };

  testIpNetworkParse4Network = {
    expr = (ip.network.prefixAddress (ip.network.parse "123.234.89.200/13")).data.raw;
    expected = [ 123 232 0 0 ];
  };

  testIpNetworkParse6Address = {
    expr = (ip.network.parse "fe80::/18").address.data.raw;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpNetworkParse6Prefix = {
    expr = (ip.network.parse "fe80::/18").prefixLength;
    expected = 18;
  };

  testIpNetworkParse6Network = {
    expr = (ip.network.prefixAddress (ip.network.parse "fe83::/15")).data.raw;
    expected = [ 254 130 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpNetworkWithHost = {
    expr = (ip.network.withHost (ip.network.parse "192.168.1.0/24") (bytes.fromInt 23)).address.data.raw;
    expected = [ 192 168 1 23 ];
  };
}
