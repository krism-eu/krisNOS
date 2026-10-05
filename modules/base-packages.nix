{ pkgs, ... }:

let
  configctl = pkgs.callPackage ../packages/kris-configctl { };
  krisApp = pkgs.callPackage ../packages/kris-app { };
in
{
  # Componenti propri del sistema.
  environment.systemPackages = with pkgs; [
    configctl
    krisApp

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
