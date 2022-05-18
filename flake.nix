{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs-channels/nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      packages.default = pkgs.callPackage ./. {};
      apps.sdefault = {
        type = "app";
        program = "${packages.default}/bin/phpmyadmin";
      };
    });
}
