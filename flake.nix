{
  description = "krisNOS: small declarative NixOS core with a mutable personal desktop layer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Flakes only see Git-tracked files, so this is true only after the real
      # hardware file has been generated AND `git add`-ed (it is not ignored).
      # Without it the Topton host would fail its fileSystems assertion, so the
      # host and its check are simply not exposed yet.
      hasHardware = builtins.pathExists ./hosts/topton-fu02/hardware-configuration.nix;
    in {
      nixosModules.krisos = import ./modules;

      nixosConfigurations = {
        # Generic/live configuration. This is also the configuration used for
        # local ISO/VM builds and does not depend on machine-specific filesystems.
        krisos-live = lib.nixosSystem {
          inherit system;
          modules = [
            self.nixosModules.krisos
            ./profiles/live.nix
          ];
        };
      } // lib.optionalAttrs hasHardware {
        # Target configuration for the personal machine.
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

        # Native NixOS image builders (nixos-generators is not required).
        iso = self.nixosConfigurations.krisos-live.config.system.build.images.iso-installer;
      };

      checks.${system} = {
        live-system = self.nixosConfigurations.krisos-live.config.system.build.toplevel;
      } // lib.optionalAttrs hasHardware {
        top-level-system = self.nixosConfigurations.krisos-topton.config.system.build.toplevel;
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
