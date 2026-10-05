{ writeShellApplication, git, nix }:
writeShellApplication {
  name = "kris-configctl";
  runtimeInputs = [ git nix ];
  text = builtins.readFile ./kris-configctl.sh;
}
