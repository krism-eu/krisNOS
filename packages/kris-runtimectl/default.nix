{
  lib,
  writeShellApplication,
  systemd,
  coreutils,
  gnused,
  util-linux,
  bluez,
}:

writeShellApplication {
  name = "kris-runtimectl";

  runtimeInputs = [
    systemd
    coreutils
    gnused
    util-linux
    bluez
  ];

  text = builtins.readFile ./kris-runtimectl.sh;

  meta = {
    description = "Helper runtime ristretto per firewall e radio Bluetooth di krisNOS";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
