# krisNOS prototype v0.6

Personal NixOS desktop architecture: **small declarative core + deliberately mutable daily-use layer**.

This is inspired by the useful parts of Xinux/SnowflakeOS (friendly ISO/software-management direction) but intentionally keeps the base close to upstream NixOS and avoids building a second distribution framework.

## What is already designed

### Declarative base

- NixOS 26.05 pin (via flake wrapper)
- systemd-boot/UEFI
- AMD/amdgpu target
- Plasma 6 + SDDM Wayland
- NetworkManager
- PipeWire/WirePlumber
- Bluetooth/BlueZ
- CUPS
- firewalld as supported NixOS firewall backend
- Flatpak
- Distrobox (Podman rootless only as its hidden engine)
- Polkit, D-Bus, udisks, upower
- ZRAM + fstrim
- no SSH server
- small base package set

### Mutable layer

- personal software through `nix profile` (`kris-app`)
- independent profile upgrade/history/rollback
- everyday administration is explicitly broad: NetworkManager, firewalld, BlueZ, CUPS, PipeWire/WirePlumber, power profiles, Flatpak, Distrobox and Plasma keep their native mutable state
- `/var/lib/krisos/runtime.conf` is only for narrow Kris policy where Nix would otherwise reassert a value; it is not the general configuration store
- `kris-runtimectl` currently prototypes firewall master state and Bluetooth rfkill; the full backend ownership map is in `docs/MUTABILITY-MATRIX.md`
- normal software stays in the user's Nix profile through `kris-app`

## Important distinction

The mutable layer is **not OverlayFS**. Nothing overlays `/nix/store`, and this prototype does not depend on the experimental writable `/etc` overlay.

## Repository layout

```text
flake.nix                      build/pinning wrapper
modules/                       reusable NixOS modules
hosts/topton-fu02/             target machine settings
profiles/live.nix              generic ISO/VM profile
packages/kris-app/             user Nix-profile helper
packages/kris-runtimectl/      allowlisted privileged runtime helper
packages/kris-configctl/       safe local/GitHub configuration exchange
docs/                          architecture and backend contracts
scripts/                       local check/VM/ISO commands
```

## First use on a NixOS development machine

```bash
git init && git add -A      # flakes only see Git-tracked files
nix flake lock && git add flake.lock
./scripts/check.sh
./scripts/build-vm.sh
./scripts/build-iso.sh
```

Without `hosts/topton-fu02/hardware-configuration.nix` only the generic live configuration (`krisos-live`) and its check are exposed; `krisos-topton` appears once the real hardware file is tracked.

The live profile logs in automatically as `kris` (throwaway password `live`, passwordless sudo): live/VM only, not the installed host. `iso-installer` is the base NixOS installer image carrying this configuration (no Calamares); the installer flow is still to be decided (see `docs/NEXT.md`).

No GitHub Actions or release workflow is required. GitHub is designed as an optional versioned exchange point; see `docs/GITHUB-SYNC.md`.

## Before installing on the Topton

Generate the real machine-specific hardware file:

```bash
sudo nixos-generate-config --show-hardware-config \
  > hosts/topton-fu02/hardware-configuration.nix
```

Then inspect it manually and track it, otherwise the flake cannot see it:

```bash
git add hosts/topton-fu02/hardware-configuration.nix
```

The file is deliberately **not** in `.gitignore` (it is not secret, and an ignored file is invisible to the flake). Do not copy example filesystem UUIDs.

## Daily software examples

```bash
kris-app search vlc
kris-app add vlc
kris-app add --unfree spotify   # unfree needs an explicit flag
kris-app list
kris-app remove vlc             # by element name, as shown by list
kris-app upgrade --dry-run
kris-app upgrade
kris-app history
kris-app rollback
```

These operations change the user's profile, **not the NixOS system generation**. `kris-app` refuses to run as root.

## Runtime examples

```bash
kris-runtimectl status
sudo kris-runtimectl firewall off
sudo kris-runtimectl bluetooth on    # immediate rfkill, not persisted
```

A future krisNCC GUI should call these through a narrow Polkit interface rather than getting arbitrary root shell access.

## Current status

Architecture/scaffold only. v0.6 keeps Distrobox the user-facing container layer, keeps Podman as hidden plumbing, and formalizes the two-repository manual-sync model (see `docs/CHANGES-v0_5.md` and `docs/CHANGES-v0_6.md`); the two helper scripts were exercised with stubbed `systemctl`/`rfkill`/`nix`, but this environment does not contain Nix, so the project still requires its first real `nix flake check` and VM boot on a NixOS/Nix-enabled machine before it is installation-ready.


## Repository model

The intended GitHub layout is now explicit:

- `krism-eu/krisNOS`: framework, modules, helpers and krisNCC contracts.
- `krism-eu/krisNOS-config`: personal machine configuration exchanged manually through krisNCC.

`krisNOS-config` is never pulled or applied automatically. No timer, boot hook or background sync is part of the design.
See `docs/REPOSITORY-MODEL.md` and the separate `krisNOS-config-seed` scaffold.

## krisNCC

The current krisCC is treated as the UI asset, not as a backend to port unchanged. Fedora-specific DNF/RPM, `rk`, bootc and raw Podman pages are replaced by Nix profile, Nix generations, native runtime APIs and Distrobox. See `docs/KRISNCC-UI.md` and `docs/MIGRATION-TO-KRISNCC.md`.
