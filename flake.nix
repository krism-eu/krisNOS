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
        kris-app = pkgs.callPackage ./packages/kris-app { };
        kris-runtimectl = pkgs.callPackage ./packages/kris-runtimectl { };
        kris-system-activate = pkgs.callPackage ./packages/kris-system-activate { };
        kris-configctl = pkgs.callPackage ./packages/kris-configctl { };
        krisNCC = krisNCCPackage;
        icicle-patched = iciclePackage;

        # Heavy outputs are explicit packages, not flake checks.
        iso = liveSystem.config.system.build.images.iso-installer;
        vm = liveSystem.config.system.build.vm;
      };

      # Keep the normal flake gate useful without pulling ISO/VM builds into it.
      # Building icicle-patch makes every --replace-fail assertion fail early
      # if the pinned upstream source stops matching our compatibility patch.
      checks.${system} = {
        krisncc-build = krisNCCPackage;
        icicle-patch = iciclePackage;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
