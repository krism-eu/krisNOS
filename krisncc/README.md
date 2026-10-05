# krisNCC

Qt 6 / KDE Kirigami control center for krisNOS.

krisNCC keeps the useful breadth and UI work of the existing krisCC while replacing Fedora-specific machinery with Nix and native Linux service backends.

## Top-level UI

- **Home** — resources and important status;
- **Sistema** — NetworkManager, Bluetooth, audio, printing, firewall, power and selected services;
- **App** — Nix, Flatpak and Distrobox;
- **Config** — personal Nix configuration, optional manual GitHub sync, diff/verify/build/apply;
- **Ripristino** — NixOS and user-profile generations;
- **Strumenti** — personal commands and useful external/KDE tools.

## Current bootstrap

Already wired:

- Home RAM excluding cache/buffers and swap, plus CPU temperature;
- Nix package search, user-profile install/remove, update preview and `nix run`;
- Distrobox inventory;
- Config local/remote status, explicit fetch/sync, scrollable diff, lock-pinned validation/build and race-safe Apply;
- firewall and simple Bluetooth ON/OFF through fixed root helpers;
- read-only NixOS/profile generation history;
- useful KDE tool launchers.

The initial personal host intentionally mirrors the convenient Fedora-era setup: `kris` has autologin, no local password and passwordless wheel administration, while root gets a separate local password during installation. krisNCC uses `sudo -n` only with its fixed helpers. This is deliberately convenient, not a security boundary, and can be tightened later.

Still pending real VM/hardware validation: Apply/rollback, systemd-boot entry retention, firewall/Bluetooth ON/OFF, full Flatpak/Distrobox mutation UI, native NetworkManager/PipeWire/CUPS/firewalld pages and kernel hardening.

## Non-negotiable rules

No background Git daemon, automatic sync/rebuild/apply, arbitrary generated root shell command or duplicate GUI state database. Native owners remain the source of truth.
