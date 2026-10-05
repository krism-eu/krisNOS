{ pkgs, ... }:

let
  configctl = pkgs.callPackage ../packages/kris-configctl { };
  krisApp = pkgs.callPackage ../packages/kris-app { };
  krisRuntimectl = pkgs.callPackage ../packages/kris-runtimectl { };
  krisNCC = pkgs.callPackage ../krisncc/package.nix { };
in
{
  # Componenti propri del sistema.
  environment.systemPackages = with pkgs; [
    configctl
    krisApp
    krisRuntimectl
    krisNCC

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
  ];
}
