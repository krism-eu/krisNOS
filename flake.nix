{
  description = "krisNOS: small declarative NixOS core with a mutable personal desktop layer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      krisosModule = import ./modules;
      krisAppPackage = pkgs.callPackage ./packages/kris-app { };
      krisRuntimectlPackage = pkgs.callPackage ./packages/kris-runtimectl { };
      krisSystemActivatePackage = pkgs.callPackage ./packages/kris-system-activate { };
      krisConfigctlPackage = pkgs.callPackage ./packages/kris-configctl { };
      krisNCCPackage = pkgs.callPackage ./krisncc/package.nix { };

      # Generic installed-system CI target. It uses the full reusable krisNOS
      # module and a harmless synthetic root filesystem.
      ciSystem = lib.nixosSystem {
        inherit system;
        modules = [
          krisosModule
          ({ lib, ... }: {
            system.stateVersion = "26.05";
            fileSystems."/" = {
              device = "/dev/disk/by-label/krisNOS-ci";
              fsType = "btrfs";
            };
            boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
          })
        ];
      };
    in
    {
      nixosModules.krisos = krisosModule;

      packages.${system} = {
        kris-app = krisAppPackage;
        kris-runtimectl = krisRuntimectlPackage;
        kris-system-activate = krisSystemActivatePackage;
        kris-configctl = krisConfigctlPackage;
        krisNCC = krisNCCPackage;
      };

      checks.${system}.krisos-system = ciSystem.config.system.build.toplevel;

      formatter.${system} = pkgs.nixfmt;
    };
}
