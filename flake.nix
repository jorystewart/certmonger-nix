{
  description = "certmonger";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
      	packages.certmonger = import ./pkgs/certmonger.nix { inherit pkgs; };
      	defaultPackage = self.packages.${system}.certmonger;
      	devShell = pkgs.mkShell {
      	  buildInputs = with pkgs; [ autoconf automake libtool pkg-config ];
      	};
      }
    );
}
