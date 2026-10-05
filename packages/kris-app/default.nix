{
  lib,
  writeShellApplication,
  nix,
  jq,
}:
writeShellApplication {
  name = "kris-app";
  runtimeInputs = [
    nix
    jq
  ];
  text = builtins.readFile ./kris-app.sh;
  meta = {
    description = "Small safe frontend for the user's mutable Nix profile";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
