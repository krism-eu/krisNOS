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
    extraGroups = [ "wheel" "networkmanager" "video" "render" "audio" "lp" ];
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };

  users.mutableUsers = true;
  system.stateVersion = "26.05";
}
