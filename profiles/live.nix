{ config, lib, pkgs, modulesPath, ... }:
{
  # Use NixOS' official installation-media base. It provides the ISO-specific
  # filesystem layout instead of requiring a real host root filesystem.
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  krisos = {
    userName = "kris";
    hostName = "krisos-live";
    autoLogin = true;
    bluetoothPowerOnBoot = false;
    mutableRuntime = true;
  };

  users.users.kris = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "render" "audio" "lp" ];
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
    initialPassword = "live";
  };

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = true;
  system.stateVersion = "26.05";
}
