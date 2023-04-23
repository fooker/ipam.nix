{
  description = "A module definition for IP Address Management in Nix.";

  outputs = { nixpkgs, ... }: {
    eval = configuration: import ./. {
      inherit (nixpkgs) lib;
      inherit configuration;
    };

    lib = import ./lib;
  };
}
