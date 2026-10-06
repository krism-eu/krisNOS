# krisNCC function map

krisNCC is not a minimal demo and it is not a universal Nix IDE. Its job is to remove routine terminal work while keeping the implementation small enough to trust and maintain.

## Home

Useful at-a-glance state only:

- CPU usage and temperature;
- RAM really in use (cache/buffers and swap excluded);
- free/total space on `/`;
- config repository state;
- firewall and Bluetooth state;
- quick links to System Monitor, System and diagnostics.

Resource polling runs only while Home is loaded.

## Sistema

Only routine controls that are worth keeping inside krisNCC:

- Bluetooth power through BlueZ/rfkill;
- firewalld master state/policy;
- restart the user PipeWire/WirePlumber stack when audio is stuck;
- power-profiles-daemon profile selection.

Wi-Fi, VPN and connection editing remain in Plasma/NetworkManager. Printers remain in the Plasma/CUPS tools. krisNCC does not build parallel UIs for mature desktop tools.

## App

Two simple views:

- Nix profile: search, install/remove, updates and `nix run` try-without-installing;
- Distrobox: current environments, with Podman kept as an implementation detail.

Flatpak management stays in Discover. krisNCC may open Discover but does not duplicate it.

## Config

Structural NixOS changes and optional GitHub exchange:

- local status;
- explicit GitHub check/fetch;
- diff;
- manual sync;
- validate;
- unprivileged build;
- explicit privileged apply through the fixed activation helper.

`krisncc-managed.nix` remains the only file intended for future curated structural controls. `free.nix` and other personal modules are never rewritten.

## Ripristino

Use Nix's native safety instead of inventing a second recovery layer:

- list NixOS generations;
- rollback to the immediately previous NixOS generation through the existing narrow `kris-system-activate` helper;
- list user profile history;
- rollback the user Nix profile;
- open Back In Time for personal file backups.

The rollback path selects the immediately previous NixOS generation read-only, resolves its canonical toplevel and delegates the privileged activation to the same fixed `kris-system-activate` helper used by Config Apply.

No `rk`, overlay request database or bootc abstraction is carried forward.

## Strumenti

The useful part of the old Fedora krisCC is retained in a smaller form:

- fixed read-only diagnostics for failed units, boot/kernel warnings, boot time, filesystem space and disks;
- up to 12 user-owned custom Bash commands;
- custom actions stored privately under `~/.config/krisNCC`, with atomic writes, no automatic privilege elevation, bounded output and cancellation;
- launchers for Plasma Settings, Info Center, System Monitor, Konsole and Discover.

No service editor, cron editor, DNF maintenance layer, Podman administration page or generic root command runner is included.

## Product rule

A function belongs in krisNCC when it is useful enough that otherwise the user would repeatedly need a terminal, remember a non-obvious command or jump through several tools.

Implementation rule: prefer the native tool and a narrow adapter. Do not reimplement NetworkManager, CUPS, Nix, Flatpak, Distrobox, Git or systemd.
