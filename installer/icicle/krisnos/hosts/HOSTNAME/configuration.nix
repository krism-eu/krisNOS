{
  config,
  lib,
  krisNOSSource,
  nixpkgsSource,
  ...
}:
{
  # nixos-generate-config writes this file at the root of the temporary
  # installer configuration. finalize-install.sh also creates the host-local
  # compatibility symlink expected by kris-configctl after installation.
  imports = [
    ../../hardware-configuration.nix
    ../../modules/local-system.nix
    ../../modules/krisncc-managed.nix
    ../../modules/free.nix
  ];

  krisos = {
    userName = "@USERNAME@";
    hostName = "@HOSTNAME@";
    bluetoothPowerOnBoot = false;
    flatpak = true;
    distrobox = true;
    mutableRuntime = true;
  };

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

  users.mutableUsers = true;
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

@AUTOLOGIN@

  # Icicle supplies a GRUB device only on legacy BIOS. On UEFI krisNOS keeps
  # its normal systemd-boot policy.
@BOOTLOADER@
  boot.loader.grub.enable = lib.mkForce (config.boot.loader.grub.device != "");
  boot.loader.systemd-boot.enable = lib.mkForce (config.boot.loader.grub.device == "");
  boot.loader.efi.canTouchEfiVariables = lib.mkForce (config.boot.loader.grub.device == "");

  # Keep the exact source trees used by the installer in the active system
  # closure. They are explicit flake inputs, so pure evaluation and later
  # rebuilds can use them without reaching GitHub.
  environment.etc."krisnos/sources/framework".source = krisNOSSource;
  environment.etc."krisnos/sources/nixpkgs".source = nixpkgsSource;

@STATEVERSION@
}
