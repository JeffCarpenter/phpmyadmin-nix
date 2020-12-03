{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs-channels/nixos-unstable";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        defaultPackage = pkgs.callPackage ./. { };
      in
      {
        inherit defaultPackage;
        defaultApp = {
          type = "app";
          program = "${defaultPackage}/bin/phpmyadmin";
        };
      });
}
