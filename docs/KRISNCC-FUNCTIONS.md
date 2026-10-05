# krisNCC function map

krisNCC is not a minimal demo and it is not a universal Nix IDE. Its job is to remove routine terminal work while keeping the implementation small enough to trust and maintain.

## Home

Useful at-a-glance state only: CPU/RAM/temperature, storage, network, app updates, current NixOS generation and config sync state. Resource polling runs only while Home is loaded.

## Sistema

Daily mutable controls. Prefer the native owner of each state:

- NetworkManager: links, Wi-Fi, VPN, DNS and connection profiles;
- BlueZ/rfkill: Bluetooth power/pairing/devices;
- PipeWire/WirePlumber: volume, devices and routes;
- CUPS: printers, queues and default printer;
- firewalld: firewall zones/rules/master state;
- power-profiles-daemon: power profile;
- systemd: runtime service status/start/stop/restart and logs where useful.

No Nix rebuild for these routine operations. krisNCC must not create a parallel database for state already owned by these services.

## App

One page, three simple tabs:

- Nix: search, install/remove, updates, `nix run` try-without-installing, user-profile history;
- Flatpak: search/install/remove/update using Flatpak itself;
- Distrobox: create/list/enter/update/remove environments and export desktop apps. Podman is an implementation detail and is not exposed as a krisNCC product concept.

## Config

Structural NixOS changes and optional GitHub exchange:

- local status;
- explicit GitHub check/fetch;
- diff;
- manual sync;
- curated structural controls (boot, ZRAM/memory, desktop, Nix, base services);
- advanced option lookup only when it saves real terminal/manual work;
- validate;
- unprivileged build;
- explicit privileged apply through the fixed activation helper via non-interactive `sudo -n` on the initial personal host.

`krisncc-managed.nix` is the only file krisNCC may regenerate. `free.nix` and other personal modules are never rewritten.

## Ripristino

Make Nix's native safety understandable instead of inventing a second recovery system:

- NixOS generations;
- profile generations;
- rollback with a clear target;
- controlled cleanup/retention;
- show which config commit was last applied.

No `rk`, overlay request database or bootc deployment abstraction is carried forward.

## Strumenti

Keep practical tools and personal commands that save repeated terminal work: Plasma Settings, Info Center, System Monitor, partition/storage tools, BackInTime and user-owned custom commands. Tools are launchers/integrations, not duplicated implementations.

## Product rule

A function belongs in krisNCC when it is useful enough that otherwise the user would repeatedly need a terminal, remember a non-obvious command or jump through several system tools.

Implementation rule: use the native API/tool and validate narrow arguments. Do not reimplement NetworkManager, CUPS, Nix, Flatpak, Distrobox, Git or systemd.
