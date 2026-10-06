{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Infrastructure lives in the base; day-to-day state is left mutable.
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  # First-boot policy: Wi-Fi starts disabled.
  # Afterwards NetworkManager owns and preserves the user's radio state.
  systemd.services.NetworkManager.preStart = lib.mkBefore ''
        state=/var/lib/NetworkManager/NetworkManager.state
        if [ ! -e "$state" ]; then
          ${pkgs.coreutils}/bin/install -d -m 0700 /var/lib/NetworkManager
          ${pkgs.coreutils}/bin/cat > "$state" <<'EOF'
    [main]
    NetworkingEnabled=true
    WirelessEnabled=false
    WWANEnabled=false
    EOF
          ${pkgs.coreutils}/bin/chmod 0600 "$state"
        fi
  '';

  # No WWAN/cellular modem on the target desktop. Plasma may otherwise
  # pull ModemManager in as an optional integration.
  networking.modemmanager.enable = false;

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
