{
  inputs = {
    krisNOS.url = "github:krism-eu/krisNOS";
    nixpkgs.follows = "krisNOS/nixpkgs";
  };

  outputs =
    { nixpkgs, krisNOS, ... }:
    {
      nixosConfigurations."@HOSTNAME@" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          krisNOS.nixosModules.krisos
          ./configuration.nix
        ];
      };
    };
}
