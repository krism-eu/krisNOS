# krisNOS architecture draft v0.6

## Goal

krisNOS is not intended to make the whole desktop declarative. It keeps a small reproducible NixOS foundation and deliberately leaves normal desktop administration mutable.

The practical rule is:

> Nix owns the foundations and installs the capabilities. Native services own day-to-day state. KrisOS adds only narrow policy glue where Nix would otherwise reassert a value.

## Layer 1 — declarative foundation (rare rebuild)

Owned by NixOS:

- bootloader, filesystems, initrd and kernel integration;
- AMD graphics/firmware;
- Plasma 6 + SDDM Wayland + portals;
- D-Bus, Polkit, udisks, upower and security/integration plumbing;
- availability of NetworkManager, PipeWire/WirePlumber, BlueZ, CUPS and firewalld;
- Flatpak and Podman infrastructure;
- Nix and KrisOS helper packages;
- structural settings that affect PAM, udev, kernel modules, boot, global service installation or system closure composition.

These changes intentionally use a NixOS generation and rebuild/switch.

## Layer 2 — mutable personal software (no NixOS rebuild)

`kris-app` manages the user's Nix profile:

- add/remove/list/upgrade applications;
- profile history;
- profile rollback.

Normal desktop applications belong here unless they need system-level integration. Flatpak remains a second mutable application backend.

## Layer 3 — mutable daily system administration (no NixOS rebuild)

This is broad and includes everything a desktop user may reasonably need to change immediately:

- NetworkManager: Wi-Fi, Ethernet, VPN, DNS, connection profiles and radios;
- firewalld: firewall state, zones, services, ports and rules;
- BlueZ/rfkill: Bluetooth radio, pairing, trust, connect/remove;
- CUPS: printers, queues, defaults and options;
- PipeWire/WirePlumber: volume, mute, default devices, profiles and routing;
- power-profiles-daemon: current power profile;
- Plasma/KConfig: desktop and application preferences;
- Podman and Flatpak normal state.

The backend uses the native owner/API first. krisNCC should not rewrite Nix files for these actions.

## Layer 4 — narrow Kris mutable policy

Some values are conceptually mutable but NixOS may regenerate/reassert the corresponding system state during activation. For these cases only, KrisOS may keep a small allowlisted policy under `/var/lib/krisos` and re-apply it safely.

The current prototype only proves this pattern with the firewall master toggle. That does **not** mean the mutable layer is limited to firewall. Most mutable settings should never be duplicated into a Kris state file because their native daemon already persists them correctly.

Settings such as hostname, global timezone/locale, service boot enablement and similar items must be classified individually as:

1. declarative foundation;
2. native mutable state; or
3. narrow Kris mutable policy.

No generic OverlayFS over `/nix/store` and no arbitrary writable `/etc` overlay are part of the design.

See `MUTABILITY-MATRIX.md`.

## Layer 5 — versioned configuration exchange

The rare declarative/base configuration lives in a normal user-owned Git checkout. A private or public GitHub repository can be the remote exchange point.

GitHub is **not** needed at boot. The PC always keeps a complete local checkout. `kris-configctl` performs conservative fetch/pull/push/sync operations and validates/builds before activation.

Recommended split:

- `krisNOS`: framework/modules/helpers/ISO tooling;
- `krisNOS-config`: personal machine configuration and safe portable preferences.

No GitHub Actions or release workflow is required for normal operation.

See `GITHUB-SYNC.md`.

## krisNCC direction

krisNCC becomes an orchestrator over explicit backends:

- Software/Nix -> `kris-app` / user Nix profile;
- Flatpak -> Flatpak;
- Containers -> Distrobox, con Podman rootless come motore nascosto;
- Network -> NetworkManager D-Bus;
- Firewall -> firewalld D-Bus/firewall-cmd;
- Bluetooth -> BlueZ D-Bus/rfkill;
- Printing -> CUPS;
- Audio -> PipeWire/WirePlumber;
- Power -> power-profiles-daemon;
- Desktop -> KDE/KConfig;
- Base -> guarded NixOS validate/build/switch;
- Config sync -> `kris-configctl`;
- Recovery -> NixOS system generations + Nix profile generations.

The GUI may present these as one coherent Control Center even though each setting remains owned by the subsystem that can persist it most reliably.
