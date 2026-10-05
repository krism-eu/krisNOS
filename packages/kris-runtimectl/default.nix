{ lib, writeShellApplication, systemd, util-linux, coreutils, gnused }:
writeShellApplication {
  name = "kris-runtimectl";
  runtimeInputs = [ systemd util-linux coreutils gnused ];
  text = builtins.readFile ./kris-runtimectl.sh;
  meta = {
    description = "Apply a tiny allowlisted mutable runtime state on krisNOS";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
