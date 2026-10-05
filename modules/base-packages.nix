{ config, pkgs, ... }:
let
  configctl = pkgs.callPackage ../packages/kris-configctl { };
  krisApp = pkgs.callPackage ../packages/kris-app { };
  krisRuntimectl = pkgs.callPackage ../packages/kris-runtimectl { };
in
{
  # Keep this deliberately short. Normal desktop applications belong to the
  # user Nix profile (or Flatpak), not environment.systemPackages.
  environment.systemPackages = with pkgs; [
    configctl
    krisApp
    krisRuntimectl
    git
    curl
    wget
    jq
    ripgrep
    pciutils
    usbutils
    lm_sensors
  ];
}
