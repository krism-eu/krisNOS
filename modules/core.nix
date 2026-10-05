{ config, lib, pkgs, ... }:
{
  networking.hostName = config.krisos.hostName;

  # These are safe defaults, not hard locks. Personal structural configuration
  # may override them from krisNOS-config without fighting the framework.
  time.timeZone = lib.mkDefault "Europe/Rome";
  i18n.defaultLocale = lib.mkDefault "it_IT.UTF-8";
  console.keyMap = lib.mkDefault "it2";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    warn-dirty = false;
  };

  nix.registry.nixpkgs.to = {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    ref = "nixos-26.05";
  };

  # Explicit/manual until krisNCC owns a visible retention policy.
  nix.gc.automatic = lib.mkDefault false;

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault config.krisos.bootEntryLimit;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  zramSwap.enable = lib.mkDefault true;
  zramSwap.algorithm = lib.mkDefault "zstd";
  zramSwap.memoryPercent = lib.mkDefault 25;

  services.fstrim.enable = true;

  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;
  programs.dconf.enable = true;

  # Deliberately no SSH server in the personal desktop base.
  services.openssh.enable = false;
}
