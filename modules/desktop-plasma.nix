{ config, lib, pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.displayManager.autoLogin = lib.mkIf config.krisos.autoLogin {
    enable = true;
    user = config.krisos.userName;
  };

  services.desktopManager.plasma6.enable = true;

  # Graphical keyboard layout. This option is also consumed by Wayland desktop
  # integrations; enabling it does not switch the Plasma session to Xorg.
  services.xserver.xkb.layout = "it";

  # Plasma's NixOS module already supplies XWayland and the KDE portal.
  # Keep the key desktop applications explicit so our UX does not depend on
  # future changes to Plasma's optional default package set.
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.kate
    kdePackages.ark
    kdePackages.okular
    kdePackages.spectacle
  ];

  # Use the NixOS integration rather than merely adding the package: this also
  # wires the service integration expected by KDE Connect.
  programs.kdeconnect.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
  ];
}
