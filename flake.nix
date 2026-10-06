{
  description = "krisNOS: small declarative NixOS core with a mutable personal desktop layer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    icicle = {
      url = "github:snowfallorg/icicle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      icicle,
    }:
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
      iciclePackage = pkgs.callPackage ./packages/icicle-patched {
        upstreamIcicle = icicle.packages.${system}.default;
      };

      # Generic live configuration. Icicle is included only in the live image;
      # the installed system is generated from installer/icicle templates and
      # imports the reusable krisNOS module.
      liveSystem = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit iciclePackage; };
        modules = [
          krisosModule
          ./profiles/live.nix
          ./profiles/icicle-installer.nix
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
        icicle-patched = iciclePackage;

        # Heavy outputs are explicit packages, not flake checks.
        iso = liveSystem.config.system.build.images.iso-installer;
        vm = liveSystem.config.system.build.vm;
      };

      # Keep the normal flake gate useful without pulling ISO/VM builds into it.
      # Build every krisNOS-owned helper plus krisNCC and the Icicle patch so
      # syntax/build regressions are caught before changes reach main.
      checks.${system} = {
        kris-app-build = krisAppPackage;
        kris-runtimectl-build = krisRuntimectlPackage;
        kris-system-activate-build = krisSystemActivatePackage;
        kris-configctl-build = krisConfigctlPackage;
        krisncc-build = krisNCCPackage;
        icicle-patch = iciclePackage;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
