{
  description = "certmonger";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      systems = flake-utils.lib.defaultSystems;
    in flake-utils.lib.eachSystem systems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        certmonger = pkgs.callPackage ./pkgs/certmonger.nix { inherit pkgs; };
        cepces = pkgs.callPackage ./pkgs/cepces.nix { inherit pkgs; };
      in {
        packages.certmonger = certmonger;
        packages.default = certmonger;
        packages.cepces = cepces;
      }
    ) // {
      nixosModules = {
        certmonger = import ./modules/certmonger.nix;
      };
    };
}
