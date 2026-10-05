{
  description = "Personal krisNOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    krisos.url = "github:krism-eu/krisNOS";
  };

  outputs = { nixpkgs, krisos, ... }:
    {
      nixosConfigurations.krisos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          krisos.nixosModules.krisos
          ./hosts/krisos/configuration.nix
        ];
      };
    };
}
