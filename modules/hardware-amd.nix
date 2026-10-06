{ lib, pkgs, ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  # Target is AMD Cezanne / amdgpu.
  # Pin the stable Linux 7.2 series explicitly; do not follow linuxPackages_latest.
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelPackages = pkgs.linuxPackages_7_2;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
}
