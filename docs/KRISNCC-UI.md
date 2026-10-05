# krisNCC — UI map

krisNCC is one Qt 6/Kirigami control center. The top-level structure is intentionally simple even though the functions are broad:

**Home · Sistema · App · Config · Ripristino · Strumenti**

The goal is not to hide useful power. It is to group it so the user does not have to remember commands or navigate a large number of technical modules.

## Home

- CPU, RAM realmente usata senza cache/buffer, temperatura;
- storage and network summary;
- current NixOS/config state;
- app/update indicators;
- a few quick actions.

Home is lightweight. Resource polling exists only while the page is loaded.

## Sistema

Immediate mutable administration through native owners:

- NetworkManager: Ethernet/Wi-Fi/VPN/DNS;
- BlueZ/rfkill: Bluetooth;
- PipeWire/WirePlumber: audio;
- CUPS: printers;
- firewalld: firewall;
- power-profiles-daemon: power;
- selected systemd runtime services/logs.

Routine changes do not rebuild NixOS.

## App

Three tabs in one place:

### Nix
Search, install/remove, update and `nix run` “Prova” in the user profile. Normal apps do not enter the system configuration.

### Flatpak
Search/install/remove/update Flatpak applications. During bootstrap Discover remains available as a fallback while the native krisNCC Flatpak view is brought over from the useful part of the old CC.

### Distrobox
Create/list/enter/update/remove environments and export graphical applications. Podman is not a product-facing page; it remains the replaceable rootless engine underneath Distrobox.

## Config

Structural NixOS configuration plus optional GitHub exchange:

- local/applied state;
- explicit GitHub check;
- diff;
- manual Sync;
- curated settings such as boot, ZRAM, desktop, Nix and base services;
- advanced option lookup where it genuinely saves manual work;
- Verify;
- Build;
- Apply.

Sync and Apply are always separate. `krisncc-managed.nix` is GUI-owned; `free.nix` and other personal modules are not rewritten.

## Ripristino

- NixOS generations;
- system rollback;
- Nix profile generations and rollback;
- explicit cleanup/retention;
- last-applied configuration commit.

Use Nix's own generations rather than recreating the Fedora-era `rk`/overlay state machine.

## Strumenti

Keep the useful lightweight parts of the current krisCC: personal commands, launchers, diagnostics, KDE tools and external backup integration. Do not duplicate a mature tool merely to make krisNCC look feature-rich.

## UI rule

Simple names and few top-level pages; rich functionality inside them. A function is worth adding when it removes repeated terminal work, a hard-to-remember operation or an unnecessarily fragmented workflow.
