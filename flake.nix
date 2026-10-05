{
  description = "krisNOS: small declarative NixOS core with a mutable personal desktop layer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      hasHardware = builtins.pathExists ./hosts/topton-fu02/hardware-configuration.nix;
    in {
      nixosModules.krisos = import ./modules;

      nixosConfigurations = {
        krisos-live = lib.nixosSystem {
          inherit system;
          modules = [
            self.nixosModules.krisos
            ./profiles/live.nix
          ];
        };
      } // lib.optionalAttrs hasHardware {
        krisos-topton = lib.nixosSystem {
          inherit system;
          modules = [
            self.nixosModules.krisos
            ./hosts/topton-fu02/configuration.nix
          ];
        };
      };

      packages.${system} = {
        kris-app = nixpkgs.legacyPackages.${system}.callPackage ./packages/kris-app { };
        kris-runtimectl = nixpkgs.legacyPackages.${system}.callPackage ./packages/kris-runtimectl { };
        kris-configctl = nixpkgs.legacyPackages.${system}.callPackage ./packages/kris-configctl { };
        krisNCC = nixpkgs.legacyPackages.${system}.callPackage ./krisncc/package.nix { };

        # Native NixOS image builders (nixos-generators is not required).
        iso = self.nixosConfigurations.krisos-live.config.system.build.images.iso-installer;
      };

      checks.${system} = {
        live-system = self.nixosConfigurations.krisos-live.config.system.build.toplevel;
        krisncc-build = self.packages.${system}.krisNCC;
      } // lib.optionalAttrs hasHardware {
        top-level-system = self.nixosConfigurations.krisos-topton.config.system.build.toplevel;
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
