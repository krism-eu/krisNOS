{
  # Small, fixed hardening delta validated on the previous Fedora base.
  # Keep this conservative: do not restrict namespaces, kexec, modules,
  # io_uring or other desktop functionality here without separate testing.
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "fs.protected_regular" = 2;
    "fs.protected_fifos" = 2;
    "fs.suid_dumpable" = 0;
  };
}
