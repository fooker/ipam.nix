# to run these tests:
# nix-instantiate --eval --strict lib/tests.nix
# if the resulting list is empty, all tests passed

{ lib ? (import <nixpkgs> { }).lib }:

with (import ./default.nix lib);

runTests {
  # bytes.nix

  testBytesFromDecEmpty = {
    expr = (bytes.fromDec [ ]).bytes;
    expected = [ ];
  };

  testBytesFromDecShort = {
    expr = (bytes.fromDec [ 42 ]).bytes;
    expected = [ 42 ];
  };

  testBytesFromDecLong = {
    expr = (bytes.fromDec [ 42 23 0 255 1 ]).bytes;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesFromBinEmpty = {
    expr = (bytes.fromBin [ ]).bytes;
    expected = [ ];
  };

  testBytesFromBinShort = {
    expr = (bytes.fromBin [ false false true false true false true false ]).bytes;
    expected = [ 42 ];
  };

  testBytesFromBinLong = {
    expr = (bytes.fromBin [
      false
      false
      true
      false
      true
      false
      true
      false
      false
      false
      false
      true
      false
      true
      true
      true
      false
      false
      false
      false
      false
      false
      false
      false
      true
      true
      true
      true
      true
      true
      true
      true
      false
      false
      false
      false
      false
      false
      false
      true
    ]).bytes;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesParseHexStringEmpty = {
    expr = (bytes.parseHexString "").bytes;
    expected = [ ];
  };

  testBytesParseHexStringShort = {
    expr = (bytes.parseHexString "2a").bytes;
    expected = [ 42 ];
  };

  testBytesParseHexStringLong = {
    expr = (bytes.parseHexString "2a1700ff01").bytes;
    expected = [ 42 23 0 255 1 ];
  };

  testBytesAsHexStringEmpty = {
    expr = (bytes.fromDec [ ]).asHexString;
    expected = "";
  };

  testBytesAsHexStringLong = {
    expr = (bytes.fromDec [ 42 23 0 255 1 ]).asHexString;
    expected = "2a1700ff01";
  };

  testBytesSlice = {
    expr = ((bytes.fromDec [ 42 23 0 255 1 ]).slice 1 3).bytes;
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
    ]).bytes;
    expected = [ 42 23 0 255 1 ];
  };

  # ip.nix

  testIpAddressParse4 = {
    expr = (ip.address.parse "1.2.3.4").bytes.bytes;
    expected = [ 1 2 3 4 ];
  };

  testIpAddressParse6Full = {
    expr = (ip.address.parse "fe80:0:0:0:0:0:0:0").bytes.bytes;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpAddressParse6Sparse = {
    expr = (ip.address.parse "fe80::0").bytes.bytes;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpAddressParse6Minimal = {
    expr = (ip.address.parse "fe80::").bytes.bytes;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpAddressToString4 = {
    expr = toString (ip.address.parse "1.2.3.4");
    expected = "1.2.3.4";
  };

  testIpAddressToString6 = {
    expr = toString (ip.address.parse "fe80::");
    expected = "fe80:0000:0000:0000:0000:0000:0000:0000";
  };

  testIpNetworkParse4Address = {
    expr = (ip.network.parse "1.2.3.4/18").address.bytes.bytes;
    expected = [ 1 2 3 4 ];
  };

  testIpNetworkParse4Prefix = {
    expr = (ip.network.parse "1.2.3.4/18").prefixLength;
    expected = 18;
  };

  testIpNetworkParse4Network = {
    expr = (ip.network.parse "123.234.89.200/13").network.bytes.bytes;
    expected = [ 123 232 0 0 ];
  };

  testIpNetworkParse6Address = {
    expr = (ip.network.parse "fe80::/18").address.bytes.bytes;
    expected = [ 254 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };

  testIpNetworkParse6Prefix = {
    expr = (ip.network.parse "fe80::/18").prefixLength;
    expected = 18;
  };

  testIpNetworkParse6Network = {
    expr = (ip.network.parse "fe83::/15").network.bytes.bytes;
    expected = [ 254 130 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
  };
}
