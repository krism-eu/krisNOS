{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.krisos = {
    userName = mkOption {
      type = types.str;
      default = "kris";
      description = "Primary local desktop user.";
    };

    hostName = mkOption {
      type = types.str;
      default = "krisos";
      description = "Default hostname.";
    };

    autoLogin = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SDDM autologin for the primary user.";
    };

    bluetoothPowerOnBoot = mkOption {
      type = types.bool;
      default = false;
      description = "Initial Bluetooth controller power policy.";
    };

    flatpak = mkOption {
      type = types.bool;
      default = true;
      description = "Keep Flatpak infrastructure in the immutable/base layer.";
    };

    distrobox = mkOption {
      type = types.bool;
      default = true;
      description = "Provide Distrobox for mutable user environments; Podman remains an internal rootless engine.";
    };

    mutableRuntime = mkOption {
      type = types.bool;
      default = true;
      description = "Enable KrisOS runtime state for immediate system toggles without a rebuild.";
    };

    bootEntryLimit = mkOption {
      type = types.int;
      default = 5;
      description = "Maximum number of systemd-boot generations exposed on the ESP.";
    };
  };
}
