# krisNCC design baseline

## Goal

krisNCC combines the useful breadth of the existing Fedora-era krisCC with the native strengths of NixOS. It should remove routine terminal work and hard-to-remember commands without turning itself into another operating-system layer.

The UI stays simple even when the capability is broad: **Home, Sistema, App, Config, Ripristino, Strumenti**. Complexity belongs behind those six areas, not in a forest of top-level modules.

## What is reused from krisCC

- Qt 6 + KDE Kirigami;
- clear sidebar with slightly larger/bold labels;
- uniform `Kirigami.AbstractCard` presentation;
- lazy loading: inactive pages are not kept alive merely because they exist;
- resource polling only while Home is loaded;
- explicit busy state for user-started mutations;
- RAM figure means used memory excluding cache/buffers and excludes swap;
- Tools and personal commands remain user-owned, not root-owned;
- detailed output is available when useful but must not dominate normal use.

Fedora-specific DNF/RPM, bootc and `rk` backends are not migrated.

## External ideas adopted selectively

### Xinux / SnowflakeOS

Adopt AppStream-like package discovery, user-profile installs, `nix run`, config/flake/host awareness and option/package metadata concepts. Do not import their GTK frontends or make normal app installs edit the system configuration.

### Nix-Gui

Adopt hierarchy/search for NixOS options, type-aware controls, current/default value, description, diff and undo. Do not adopt a universal-parser architecture as a required foundation.

### NiCo

Adopt visible generated Nix for advanced structural edits, validation before activation and Git-aware safety. Improve Nix-Brix by ownership at file level: krisNCC writes only `krisncc-managed.nix`; free personal Nix lives in separate files that krisNCC never rewrites.

### MyNixOS

Adopt the module/import mental model and type-driven forms where useful. Raw Nix is an advanced fallback, not the normal interface. No web service is required.

### NixNG

No runtime/code dependency. The useful lesson is simply to keep modules small and foundations minimal.

## Three ownership layers

1. **Foundations** — boot, kernel, hardware integration, Plasma/SDDM, Nix and service availability. NixOS owns these and rebuilds are deliberate.
2. **Daily state** — NetworkManager, BlueZ, PipeWire/WirePlumber, CUPS, firewalld, power profiles, Flatpak and Distrobox. Their native services own state and changes are immediate.
3. **Personal structure** — curated NixOS settings in `krisNOS-config`, optionally exchanged through GitHub. krisNCC may edit only its owned module after showing a diff.

User software via `nix profile` sits deliberately outside the system rebuild cycle.

## Safety and maintenance rules

- GitHub is optional; no background Git polling or auto-sync;
- Sync never means Apply;
- normal app install never triggers a system rebuild;
- build and apply are separate operations;
- no arbitrary shell execution as root;
- privileged actions use fixed helpers and validated arguments; on the initial personal host they are invoked through non-interactive `sudo -n`;
- no hidden krisNCC database becomes a second source of truth;
- native service state stays native;
- structural defaults in krisNOS use `mkDefault` when personal configuration is expected to override them;
- free Nix is never rewritten by the GUI;
- features are added because they eliminate real manual work, not because another control center happens to expose them.

See `KRISNCC-FUNCTIONS.md` for the functional map.
