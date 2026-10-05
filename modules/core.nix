{ config, lib, pkgs, ... }:
{
  networking.hostName = config.krisos.hostName;

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";
  console.keyMap = "it2";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    warn-dirty = false;
  };

  # `nixpkgs#foo` used by the mutable user profile follows the stable branch
  # instead of drifting to an unrelated registry target. It is still an
  # unlocked branch, so `nix profile upgrade --all` can advance normally.
  nix.registry.nixpkgs.to = {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    ref = "nixos-26.05";
  };

  # Garbage collection is deliberately manual in the prototype. Automatic GC
  # can also prune profile generations, which would make GUI rollback retention
  # surprising. krisNCC will eventually own an explicit retention policy.
  nix.gc.automatic = false;

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault config.krisos.bootEntryLimit;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

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
