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

      # Build the installer templates once per ISO and bake in the exact source
      # store paths used for this build. Both become explicit local path inputs
      # in the installed flake, so pure evaluation accepts them without network
      # resolution. The framework input is flake=false to avoid pulling the
      # installer-only Icicle dependency graph into the installed system.
      installerConfig =
        pkgs.runCommand "krisnos-icicle-config"
          {
            nativeBuildInputs = [ pkgs.gnused ];
          }
          ''
            mkdir -p "$out"
            cp -R ${./installer/icicle}/. "$out/"
            chmod -R u+w "$out"

            substituteInPlace "$out/krisnos/flake.nix" \
              --replace-fail '@FRAMEWORK_SOURCE@' '${self.outPath}' \
              --replace-fail '@NIXPKGS_SOURCE@' '${nixpkgs.outPath}'

            if grep -R -n -E '@(FRAMEWORK_SOURCE|NIXPKGS_SOURCE)@' "$out/krisnos"; then
              echo "installer source placeholder left unresolved" >&2
              exit 1
            fi
          '';

      # Generic installed-system CI target. It uses the full reusable krisNOS
      # module and a harmless synthetic root filesystem, but no live ISO or
      # installer layer. Building its toplevel validates the complete base OS.
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

      # Generic live configuration. Icicle is included only in the live image;
      # the installed system is generated from the installer templates.
      liveSystem = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit iciclePackage installerConfig;
        };
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
        installer-config = installerConfig;

        # Heavy outputs are explicit packages, not normal flake checks.
        iso = liveSystem.config.system.build.images.iso-installer;
        vm = liveSystem.config.system.build.vm;
      };

      # Normal gate: build the complete installed-system base, not a hand-picked
      # package list. Any change to modules, services, Plasma, AMD support,
      # packages or krisNCC must still produce a valid NixOS system toplevel.
      checks.${system}.krisos-system = ciSystem.config.system.build.toplevel;

      formatter.${system} = pkgs.nixfmt;
    };
}
