{
  icicle,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  upstreamIcicle = icicle.packages.${system}.default;

  # Icicle still emits a few pre-23.11 NixOS option paths. Keep the upstream
  # installer and patch only those generated snippets so the user's choices
  # (autologin and keyboard) evaluate cleanly on the pinned NixOS 26.05 base.
  iciclePackage = upstreamIcicle.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/utils/install.rs \
        --replace-fail 'services.xserver.displayManager.autoLogin.enable' 'services.displayManager.autoLogin.enable' \
        --replace-fail 'services.xserver.displayManager.autoLogin.user' 'services.displayManager.autoLogin.user' \
        --replace-fail 'services.xserver.layout' 'services.xserver.xkb.layout' \
        --replace-fail 'xkbVariant =' 'xkb.variant ='
    '';
  });

  icicleAutostart = pkgs.makeAutostartItem {
    name = "org.snowflakeos.Icicle";
    package = iciclePackage;
  };
in
{
  # Icicle exists only in the live ISO. The installed system is generated from
  # the templates under installer/icicle and imports the krisNOS framework.
  environment.systemPackages = [
    iciclePackage
    icicleAutostart
    pkgs.gparted
  ];

  environment.etc."icicle".source = ../installer/icicle;
}
