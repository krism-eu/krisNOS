{
  lib,
  writeShellApplication,
  nix,
  coreutils,
}:
writeShellApplication {
  name = "kris-system-activate";
  runtimeInputs = [
    nix
    coreutils
  ];
  text = builtins.readFile ./kris-system-activate.sh;
  meta = {
    description = "Narrow privileged NixOS activation helper for krisNOS";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
