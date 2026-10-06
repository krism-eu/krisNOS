{ ... }:
{
  imports = [
    ./options.nix
    ./core.nix
    ./hardware-amd.nix
    ./hardening.nix
    ./desktop-plasma.nix
    ./services.nix
    ./mutable-layer.nix
    ./base-packages.nix
  ];
}
