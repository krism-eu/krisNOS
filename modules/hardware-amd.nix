{ config, lib, ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  # Target is AMD Cezanne / amdgpu. Keep the distribution kernel instead of
  # forcing linuxPackages_latest: fewer self-imposed maintenance surprises.
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
}
