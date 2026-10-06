{
  iciclePackage,
  installerConfig,
  pkgs,
  ...
}:

let
  icicleAutostart = pkgs.makeAutostartItem {
    name = "org.snowflakeos.Icicle";
    package = iciclePackage;
  };
in
{
  # Icicle exists only in the live ISO. The generated installerConfig contains
  # the exact krisNOS and nixpkgs source store paths used to build this ISO, so
  # the installation itself does not need GitHub or another network source.
  environment.systemPackages = [
    iciclePackage
    icicleAutostart
    pkgs.gparted
  ];

  environment.etc."icicle".source = installerConfig;
}
