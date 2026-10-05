{ config, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Icicle owns installation-time choices. krisNOS supplies the reusable base.
  krisos = {
    userName = "@USERNAME@";
    hostName = "@HOSTNAME@";
    autoLogin = false;
    bluetoothPowerOnBoot = false;
    flatpak = true;
    distrobox = true;
    mutableRuntime = true;
  };

@NETWORK@

@TIMEZONE@

@LOCALE@

@KEYBOARD@

  users.users."@USERNAME@" = {
    isNormalUser = true;
    description = "@FULLNAME@";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "audio"
      "lp"
    ];
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  # Passwords are written by Icicle after nixos-install and are never stored in
  # this template. The normal NixOS sudo policy remains in force.
  users.mutableUsers = true;
  security.sudo.enable = true;

@AUTOLOGIN@

  # Icicle supplies a GRUB device only on legacy BIOS. On UEFI krisNOS keeps
  # its normal systemd-boot policy. This makes the installer neutral on disk
  # layout without hard-coding the target drive.
@BOOTLOADER@
  boot.loader.grub.enable = lib.mkForce (config.boot.loader.grub.device != "");
  boot.loader.systemd-boot.enable = lib.mkForce (config.boot.loader.grub.device == "");
  boot.loader.efi.canTouchEfiVariables = lib.mkForce (config.boot.loader.grub.device == "");

@STATEVERSION@
}
