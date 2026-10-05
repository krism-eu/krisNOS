{
  icicle,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  iciclePackage = icicle.packages.${system}.default;
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
