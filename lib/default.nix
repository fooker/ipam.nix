lib:

lib.extend (self: super: {
  types = import ./types.nix { inherit self super; };
  ip = import ./ip.nix { inherit self super; };
  bytes = import ./bytes.nix { inherit self super; };
})
