{ config, lib, pkgs, ... }:
let
  runtimectl = pkgs.callPackage ../packages/kris-runtimectl { };
in
{
  config = lib.mkIf config.krisos.mutableRuntime {
    # /var/lib/krisos/runtime.conf is intentionally outside /etc and /nix/store.
    # v0.4 uses FIREWALL only as the first proof of the narrow Kris-policy pattern.
    # CUPS, NetworkManager and BlueZ keep their own native state instead.

    # While FIREWALL=off, firewalld is skipped (not failed) whoever starts it:
    # boot, activation or `nixos-rebuild switch`. Missing/corrupt state defaults
    # to on, so a damaged state file never silently disables the firewall.
    systemd.services.firewalld = lib.mkIf config.services.firewalld.enable {
      serviceConfig.ExecCondition = "${runtimectl}/bin/kris-runtimectl is-on firewall";
    };
  };
}
