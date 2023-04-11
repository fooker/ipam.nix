{ pkgs ? import <nixpkgs> { } }:

let
  nix-pre-commit-hooks = (import (builtins.fetchTarball "https://github.com/cachix/pre-commit-hooks.nix/tarball/master")).run {
    src = ./.;
    hooks = {
      nixpkgs-fmt.enable = true;
      statix.enable = true;
    };
  };

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    bash
    gitAndTools.git
    nixpkgs-fmt
    statix
  ];

  inherit (nix-pre-commit-hooks) shellHook;
}

