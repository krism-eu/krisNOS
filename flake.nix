{
  description = "krisNOS: small declarative NixOS core with a mutable personal desktop layer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      krisosModule = import ./modules;

      # Generic live configuration. Image/VM-specific modules are applied
      # through system.build.images / system.build.vm rather than pretending
      # this is an installed physical host.
      liveSystem = lib.nixosSystem {
        inherit system;
        modules = [
          krisosModule
          ./profiles/live.nix
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
