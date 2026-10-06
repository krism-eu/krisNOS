{
  description = "krisNOS installer and live ISO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Il sistema vero vive su main. Il lock della branch iso fissa una revisione
    # esatta, quindi ogni ISO è riproducibile e non segue main automaticamente.
    krisNOS = {
      url = "github:krism-eu/krisNOS/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    icicle = {
      url = "github:snowfallorg/icicle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      krisNOS,
      icicle,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Framework/runtime preso dalla revisione di main fissata nel lock.
      krisosModule = krisNOS.nixosModules.krisos;

      iciclePackage = pkgs.callPackage ./packages/icicle-patched {
        upstreamIcicle = icicle.packages.${system}.default;
      };

      # La configurazione generata dall'installer contiene esattamente le
      # sorgenti krisNOS/main e nixpkgs usate per costruire questa ISO.
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
              --replace-fail '@FRAMEWORK_SOURCE@' '${krisNOS.outPath}' \
              --replace-fail '@NIXPKGS_SOURCE@' '${nixpkgs.outPath}'

            if grep -R -n -E '@(FRAMEWORK_SOURCE|NIXPKGS_SOURCE)@' "$out/krisnos"; then
              echo "installer source placeholder left unresolved" >&2
              exit 1
            fi
          '';

      liveSystem = nixpkgs.lib.nixosSystem {
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
      packages.${system} = {
        icicle-patched = iciclePackage;
        installer-config = installerConfig;
        iso = liveSystem.config.system.build.images.iso-installer;
        vm = liveSystem.config.system.build.vm;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
