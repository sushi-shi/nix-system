{
  description = "Sheep NixOS configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "path:/home/sheep/nixos/secrets.nix";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, secrets, ... }:
  let
    system = "x86_64-linux";
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  in {
    nixosConfigurations.sheep = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit pkgs-unstable;
        secrets = import secrets;
      };

      modules = [
        ./system/configuration.nix

        home-manager.nixosModules.home-manager {
          home-manager.extraSpecialArgs = { inherit pkgs-unstable; };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.sheep = import ./user/home.nix;
        }
      ];
    };
  };
}
