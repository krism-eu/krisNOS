{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.hostName = config.krisos.hostName;

  # These are safe defaults, not hard locks. Personal structural configuration
  # may override them from krisNOS-config without fighting the framework.
  time.timeZone = lib.mkDefault "Europe/Rome";
  i18n.defaultLocale = lib.mkDefault "it_IT.UTF-8";
  console.keyMap = lib.mkDefault "it2";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    warn-dirty = false;
  };

  # NixOS upstream adds perl/rsync/strace as convenience defaults. They are
  # not part of the krisNOS foundation; install them in the user profile when
  # actually needed. Keep environment.corePackages untouched.
  environment.defaultPackages = lib.mkDefault [ ];

  # Explicit/manual until krisNCC owns a visible retention policy.
  nix.gc.automatic = lib.mkDefault false;

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault config.krisos.bootEntryLimit;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  zramSwap.enable = lib.mkDefault true;
  zramSwap.algorithm = lib.mkDefault "zstd";
  zramSwap.memoryPercent = lib.mkDefault 25;

  services.fstrim.enable = true;
  boot.zfs.forceImportRoot = false;

  # Polkit remains available for normal desktop integrations. krisNCC itself
  # uses the host's explicit sudo policy for its fixed administrative helpers.
  security.polkit.enable = true;

  security.rtkit.enable = true;

  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;
  programs.dconf.enable = true;

  # Deliberately no SSH server in the personal desktop base.
  services.openssh.enable = false;
}
