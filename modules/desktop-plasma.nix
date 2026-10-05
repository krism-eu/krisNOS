{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.displayManager.autoLogin = lib.mkIf config.krisos.autoLogin {
    enable = true;
    user = config.krisos.userName;
  };

  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = false;
  };

  services.xserver.xkb.layout = "it";

  # Manteniamo tutto il core Plasma richiesto da NixOS.
  # Escludiamo solo applicazioni/funzionalita opzionali che non vogliamo
  # nella base.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    aurorae
    plasma-browser-integration
    plasma-workspace-wallpapers

    konsole
    kwin-x11
    (lib.getBin qttools)

    ark
    elisa
    gwenview
    okular
    kate
    khelpcenter
    dolphin
    baloo-widgets
    dolphin-plugins
    spectacle
    ffmpegthumbs
    krdp

    plasma-keyboard
    qtvirtualkeyboard

    qrca
    discover
  ];

  # Applicazioni KDE che vogliamo garantire esplicitamente nella base.
  environment.systemPackages = with pkgs.kdePackages; [
    dolphin
    konsole
    kate
    ark
    okular
    spectacle
    discover
  ];

  # KDE Connect verra installato manualmente fuori dalla base.
  programs.kdeconnect.enable = false;

  programs.kde-pim.enable = false;
  services.fwupd.enable = false;
  services.geoclue2.enable = false;
  services.orca.enable = false;

  # ktexteditor, kconfig e qtbase NON vengono esclusi:
  # servono alle integrazioni desktop/Kate/xdg.
  fonts.packages = [
    pkgs.noto-fonts-color-emoji
  ];
}
