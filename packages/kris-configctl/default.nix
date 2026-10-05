{
  writeShellApplication,
  callPackage,
  git,
  nix,
  jq,
  coreutils,
  gnused,
  gawk,
  sudo,
}:
let
  krisSystemActivate = callPackage ../kris-system-activate { };
in
writeShellApplication {
  name = "kris-configctl";
  runtimeInputs = [
    git
    nix
    jq
    coreutils
    gnused
    gawk
    sudo
    krisSystemActivate
  ];
  text = builtins.readFile ./kris-configctl.sh;
}
