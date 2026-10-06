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
  bash,
  coreutils,
  systemd,
  power-profiles-daemon,
}:

let
  krisApp = callPackage ../packages/kris-app { };
  krisConfigctl = callPackage ../packages/kris-configctl { };
  krisRuntimectl = callPackage ../packages/kris-runtimectl { };
  krisSystemActivate = callPackage ../packages/kris-system-activate { };
in

stdenv.mkDerivation {
  pname = "krisNCC";
  version = "0.2.0";
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
        bash
        coreutils
        systemd
        power-profiles-daemon
        kdePackages.kdialog
        krisApp
        krisConfigctl
        krisRuntimectl
        krisSystemActivate
      ]
    }"
  ];

  cmakeFlags = [ "-GNinja" ];
}
