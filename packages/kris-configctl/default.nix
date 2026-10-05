{
  writeShellApplication,
  callPackage,
  git,
  nix,
  jq,
  coreutils,
  gnused,
  gawk,
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
    krisSystemActivate
  ];
  text = builtins.readFile ./kris-configctl.sh;
}
