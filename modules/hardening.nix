{ lib, ... }:
{
  # Small, fixed hardening delta validated on the previous Fedora base.
  # Keep this conservative: do not restrict namespaces, kexec, modules,
  # io_uring or other desktop functionality here without separate testing.
  # Priority 900 beats NixOS mkDefault values while still allowing ordinary
  # personal declarative settings to override these framework defaults.
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = lib.mkOverride 900 2;
    "fs.protected_regular" = lib.mkOverride 900 2;
    "fs.protected_fifos" = lib.mkOverride 900 2;
    "fs.suid_dumpable" = lib.mkOverride 900 0;
  };
}
