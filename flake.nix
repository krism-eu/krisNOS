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
    { self, nixpkgs, icicle }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      krisosModule = import ./modules;

      # Generic live configuration. Icicle is included only in the live image;
      # the installed system is generated from installer/icicle templates and
      # imports the reusable krisNOS module.
      liveSystem = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit icicle; };
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

        # Heavy outputs are explicit packages, not flake checks.
        iso = liveSystem.config.system.build.images.iso-installer;
        vm = liveSystem.config.system.build.vm;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
