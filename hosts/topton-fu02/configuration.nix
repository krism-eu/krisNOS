{ config, lib, pkgs, ... }:
let
  hw = ./hardware-configuration.nix;
in
{
  imports = lib.optional (builtins.pathExists hw) hw;

  krisos = {
    userName = "kris";
    hostName = "krisos";
    autoLogin = true;
    bluetoothPowerOnBoot = false;
    flatpak = true;
    distrobox = true;
    mutableRuntime = true;
  };

  users.users.${config.krisos.userName} = {
    isNormalUser = true;
    description = "KrisOS user";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "audio"
      "lp"
    ];

    # Rootless Podman UID/GID mapping used internally by Distrobox.
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };

  # Keep user account credentials out of Git. Set the password locally with
  # passwd after installation, or add a hashedPasswordFile outside the repo.
  users.mutableUsers = true;


  # Installation compatibility baseline; host/profile owned, not reusable module state.
  system.stateVersion = "26.05";
}
