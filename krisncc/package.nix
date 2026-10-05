{
  stdenv,
  lib,
  callPackage,
  cmake,
  ninja,
  pkg-config,
  qt6,
  kdePackages,
  nix,
  util-linux,
  bluez,
  sudo,
}:

let
  krisApp = callPackage ../packages/kris-app { };
  krisConfigctl = callPackage ../packages/kris-configctl { };
  krisRuntimectl = callPackage ../packages/kris-runtimectl { };
in

stdenv.mkDerivation {
  pname = "krisNCC";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    kdePackages.kirigami
  ];

  qtWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        nix
        util-linux
        bluez
        sudo
        krisApp
        krisConfigctl
        krisRuntimectl
      ]
    }"
  ];

  cmakeFlags = [ "-GNinja" ];
}
