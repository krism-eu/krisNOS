{
  config,
  lib,
  pkgs,
  ...
}:

let
  configctl = pkgs.callPackage ../packages/kris-configctl { };
  krisApp = pkgs.callPackage ../packages/kris-app { };
  krisRuntimectl = pkgs.callPackage ../packages/kris-runtimectl { };
  krisNCC = pkgs.callPackage ../krisncc/package.nix { };

  resolveSystemPackage =
    attr:
    let
      path = lib.splitString "." attr;
    in
    if lib.hasAttrByPath path pkgs then
      lib.getAttrFromPath path pkgs
    else
      throw "krisNOS: unknown nixpkgs system package attribute '${attr}'";

  extraSystemPackages = map resolveSystemPackage config.krisos.extraSystemPackages;
in
{
  nixpkgs.config.allowUnfree = lib.mkDefault config.krisos.allowUnfreeSystemPackages;

  # Componenti propri del sistema + pacchetti scelti esplicitamente da krisNCC.
  environment.systemPackages =
    (with pkgs; [
      configctl
      krisApp
      krisRuntimectl
      krisNCC

      # Backup personale: motore esterno dedicato, non duplicato in krisNCC.
      backintime-qt

      # Amministrazione locale essenziale.
      git
      curl
      nano
      rsync
      unzip

      # Rete.
      iproute2
      iputils
      ethtool

      # Diagnostica hardware/storage.
      pciutils
      usbutils
      smartmontools
      nvme-cli
    ])
    ++ extraSystemPackages;
}
