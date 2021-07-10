{ pkgs ? import <nixpkgs> {} }:

let
  nix-pre-commit-hooks = (import (builtins.fetchTarball "https://github.com/cachix/pre-commit-hooks.nix/tarball/master")).run {
    src = ./.;
    hooks = {
      nixpkgs-fmt = {
        enable = true;
        excludes = [ "^nix/" ];
      };

      nix-linter = {
        enable = true;
        excludes = [ "^nix/" ];
      };
    };
    settings = {
      nix-linter.checks = [ "No-UnfortunateArgName" ];
    };
  };

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    bash
    gitAndTools.git
    nixpkgs-fmt
    nix-linter
    shellcheck
  ];

  inherit (nix-pre-commit-hooks) shellHook;
}

