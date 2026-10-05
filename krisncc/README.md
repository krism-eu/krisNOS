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

The names are simple; the capabilities behind them can be broad.

## Current bootstrap

Already wired:

- Home RAM value excluding cache/buffers and swap, plus CPU temperature;
- Nix package search, user-profile install/remove, update preview and `nix run` try-without-installing;
- Distrobox inventory;
- Config local/remote status, explicit fetch/sync, diff, validation and unprivileged build;
- Bluetooth/firewall immediate toggles through the restricted runtime helper;
- read-only NixOS/profile generation history;
- useful KDE tool launchers.

Not yet enabled until the relevant contract is tested: privileged NixOS Apply, system rollback, full Flatpak/Distrobox mutation UI and full native NetworkManager/BlueZ/PipeWire/CUPS/firewalld pages.

## Non-negotiable rules

No background daemon, automatic Git sync, automatic rebuild, hidden `sudo`, arbitrary root shell execution or GUI-owned duplicate state database.
