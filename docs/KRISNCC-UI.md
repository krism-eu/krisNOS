# krisNCC — target UI and reuse plan

The goal is one Qt 6/Kirigami control center. Xinux/SnowflakeOS are references for package discovery and Nix option presentation, not extra desktop applications to ship alongside it.

## Navigation

### Dashboard
- CPU, real-used RAM, temperature, storage, network;
- current NixOS generation;
- personal Nix profile status;
- Git config state: local/remote/applied commit;
- important runtime state only.

### Sistema
Fast, mutable administration through native owners:
- NetworkManager: Ethernet/Wi-Fi/VPN/DNS;
- BlueZ/rfkill: Bluetooth;
- PipeWire/WirePlumber: audio devices/profiles/defaults;
- CUPS: printers/queues/defaults;
- firewalld: state/zones/services/rules;
- power-profiles-daemon: power profile;
- selected systemd runtime start/stop/restart/logs.

Structural NixOS settings are visibly separated under **Fondamenta** and are never presented as instant runtime toggles.

### Software
- Nix package search inspired by Xinux/SnowflakeOS software centers;
- install/remove/upgrade in the user `nix profile` by default;
- profile generations/history/rollback;
- Flatpak as a second source;
- optional `nix run` “Prova” action for suitable packages.

No DNF/RPM code.

### Distrobox
- create environment;
- list/status;
- enter in Konsole;
- stop/remove/upgrade;
- export/list graphical apps where supported.

Podman is not a visible section. It is only the rootless engine underneath Distrobox and can be replaced later without redesigning the UI.

### Configurazione
Local source configuration plus optional GitHub exchange:
- local commit;
- remote commit after explicit check;
- applied commit;
- diff;
- manual Sync;
- Validate;
- Build;
- Apply.

Sync and Apply are always separate. There is no automatic sync.

Advanced view can later expose selected NixOS options by type (bool -> switch, enum -> combo, integer -> spinbox, etc.), inspired by NixOS Configuration Editor, without attempting to make every Nix expression editable graphically.

### Recovery
- NixOS generations;
- previous generation / rollback;
- Nix profile generations independently;
- explicit cleanup/retention.

No `rk`, overlay transaction state or bootc deployment parser.

### Strumenti
Keep the useful lightweight parts of the current krisCC: personal commands, launchers and selected diagnostics. External backup remains an external tool/launcher unless a compelling Nix-native integration proves simpler.

## Maintenance rule

Prefer native D-Bus/API/CLI contracts over a Kris-owned state machine. A custom helper is justified only when it gives a narrow privilege boundary or a stable JSON contract that the upstream component does not provide.
