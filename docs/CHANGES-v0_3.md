# Changes v0.2 -> v0.3

1. **Ownership simplification**: removed the custom persistent `PRINTING` toggle and `krisos-runtime-apply` boot service. CUPS remains declared once and owns printers/queues/runtime state natively.
2. **Firewall mutable state**: `/var/lib/krisos/runtime.conf` now contains only `FIREWALL=on|off`; the existing fail-safe `ExecCondition` remains the rebuild/boot guard.
3. **Bluetooth**: remains an immediate rfkill action and native systemd-rfkill/BlueZ state; no duplicate KrisOS persistence.
4. **GUI contract**: `kris-runtimectl status --json` now returns `schema: 1`.
5. **Host compatibility**: moved `system.stateVersion = "26.05"` from the reusable core module to `profiles/live.nix` and `hosts/topton-fu02/configuration.nix`.
6. **Boot retention**: added `krisos.bootEntryLimit` (default 5) and wired it to `boot.loader.systemd-boot.configurationLimit`.
7. **GC policy**: automatic Nix GC is disabled for now; rollback retention must be explicit rather than silently pruning profile/system history.
8. **Desktop input**: explicitly sets Italian graphical XKB layout while keeping Plasma Wayland as the session.

Still requires a real NixOS 26.05 `nix flake check`, VM boot and ISO boot. The open firewalld reverse-path-filter issue remains a pre-install blocker to verify against the pinned revision.
