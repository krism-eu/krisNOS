{ stdenv, cmake, ninja, pkg-config, qt6, kdePackages }:
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
    kdePackages.kirigami
  ];

  cmakeFlags = [ "-GNinja" ];
}
