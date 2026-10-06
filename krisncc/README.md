# krisNCC

Qt 6 / KDE Kirigami control center for krisNOS.

krisNCC keeps the useful daily functions of the Fedora-era krisCC while replacing Fedora-specific machinery with NixOS and native desktop/service tools. The goal is useful, not maximal: mature Plasma applications are opened instead of reimplemented.

## Top-level UI

- **Home** — CPU/RAM/temperature, root filesystem space and important status;
- **Sistema** — Bluetooth, firewall, audio recovery and power profile;
- **App** — Nix user profile and Distrobox; Discover remains the Flatpak GUI;
- **Config** — personal Nix configuration, optional manual GitHub sync, diff/verify/build/apply;
- **Ripristino** — NixOS/profile generations, rollback and Back In Time;
- **Strumenti** — read-only diagnostics, up to 12 personal commands and useful KDE launchers.

## Current implementation

Wired:

- RAM really used (cache/buffers and swap excluded), CPU usage/temperature and root filesystem space;
- Nix package search, user-profile install/remove, update preview and `nix run`;
- Distrobox inventory;
- Config local/remote status, explicit fetch/sync, diff, lock-pinned validation/build and race-safe Apply;
- firewall and Bluetooth ON/OFF through fixed helpers;
- PipeWire/WirePlumber user-stack restart;
- power-profiles-daemon profile selection;
- NixOS and user-profile generation history;
- rollback to the previous NixOS generation through the existing `kris-system-activate` helper;
- user-profile rollback;
- Back In Time for personal backups;
- fixed read-only diagnostics;
- up to 12 private user-owned Bash actions with no automatic privilege elevation;
- Plasma Settings, Info Center, System Monitor, Konsole and Discover launchers.

Wi-Fi/VPN remain in Plasma/NetworkManager. Flatpak remains in Discover. Printers remain in Plasma/CUPS. krisNCC does not duplicate those interfaces.

The initial personal host intentionally mirrors the convenient setup selected for krisNOS: `kris` has autologin, no local password and passwordless wheel administration, while root gets a separate local password during installation. krisNCC uses `sudo -n` only with fixed helpers.

## Non-negotiable rules

No background Git daemon, automatic sync/rebuild/apply, arbitrary generated root shell command, generic service editor or duplicate GUI state database. Native owners remain the source of truth.

A privileged feature must have a narrow helper, fixed operation set, input validation and a post-operation check where possible.
