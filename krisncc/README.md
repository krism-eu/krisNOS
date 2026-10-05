# krisNCC

Qt 6 / KDE Kirigami control center for krisNOS.

This directory is the clean NixOS-oriented successor of `krisCC`. It intentionally keeps the parts that worked well in the existing application (Kirigami shell, clear sidebar, lazy page loading, lightweight dashboard, explicit operations) and drops Fedora/bootc-specific backends.

## Bootstrap scope

The first implementation provides:

- Dashboard with RAM used **without cache/buffers**, CPU temperature and local configuration/runtime status;
- Software page using the user Nix profile (`kris-app`) plus `nix run` for try-without-installing;
- Configuration page using `kris-configctl`; remote contact and synchronization are always explicit user actions;
- Distrobox inventory (Podman remains an internal engine, not a krisNCC page);
- read-only NixOS/profile recovery history;
- System and Tools landing pages ready for native NetworkManager/BlueZ/PipeWire/CUPS/firewalld integration.

## Design rule

krisNCC does not try to become a universal Nix parser. Curated structural settings will eventually be written only to a krisNCC-owned module in `krisNOS-config`; free Nix modules remain untouched.

No background daemon, automatic Git sync, automatic rebuild or automatic apply is part of krisNCC.
