{ lib, ... }:
{
  # Small, fixed hardening delta validated on the previous Fedora base.
  # Keep this conservative: do not restrict namespaces, kexec, modules,
  # io_uring or other desktop functionality here without separate testing.
  # Values are defaults so personal declarative configuration can override them.
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = lib.mkDefault 2;
    "fs.protected_regular" = lib.mkDefault 2;
    "fs.protected_fifos" = lib.mkDefault 2;
    "fs.suid_dumpable" = lib.mkDefault 0;
  };
}
