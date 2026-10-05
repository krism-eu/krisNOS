{ config, lib, pkgs, ... }:
{
  # Infrastructure lives in the base; day-to-day state is left mutable.
  networking.networkmanager.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = config.krisos.bluetoothPowerOnBoot;
  };

  # Keep CUPS installed and socket-activatable. Printer queues/settings remain
  # normal mutable CUPS state; we do not maintain a second KrisOS on/off state.
  services.printing.enable = true;

  # firewalld uses nftables by default on current NixOS. Enable the nftables
  # infrastructure explicitly, as required by the NixOS firewalld backend.
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    backend = "firewalld";
  };
  services.firewalld.enable = true;

  services.flatpak.enable = config.krisos.flatpak;

  # Distrobox is the user-facing container feature. Podman is deliberately kept
  # as a hidden rootless engine because Distrobox needs a container manager.
  # krisNCC should expose Distrobox concepts, not raw Podman administration.
  virtualisation.podman = lib.mkIf config.krisos.distrobox {
    enable = true;
    dockerCompat = false;
  };
  environment.systemPackages = lib.optionals config.krisos.distrobox [ pkgs.distrobox ];

  services.power-profiles-daemon.enable = true;
}
