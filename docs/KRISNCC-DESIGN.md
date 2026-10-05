# krisNCC design baseline

## What is reused from krisCC

- Qt 6 + KDE Kirigami;
- clear left sidebar with slightly larger/bold labels;
- uniform `Kirigami.AbstractCard` presentation;
- lazy loading of pages;
- resource polling only while the Dashboard is visible;
- explicit busy state and refusal to close during user-started mutations;
- RAM figure means used memory excluding cache/buffers and excludes swap;
- Tools and personal commands remain user-owned, not root-owned.

Fedora-specific DNF/RPM, bootc and `rk` backends are not migrated.

## Ideas adopted selectively

### Xinux / SnowflakeOS

Adopt:
- AppStream-like package discovery and clean Nix package search;
- user-profile installs without system rebuild;
- `nix run` to try software without installing it;
- explicit config path/flake/host awareness;
- separation between software management and structural Nix settings;
- the `nix-data` idea of caching package/NixOS option metadata for GUI clients.

Do not adopt:
- GTK/libadwaita frontend;
- promotional store front/carousels as a required feature;
- automatic editing of the main system config for normal app installs;
- a mandatory external metadata daemon/library.

The bootstrap invokes Nix directly. A later optimization may build a versioned metadata cache (packages/options) keyed to the pinned nixpkgs/config revision. For application presentation we prefer existing NixOS AppStream data rather than maintaining a second package catalogue ourselves.

### Nix-Gui

Adopt:
- hierarchy/search for NixOS options;
- type-aware widgets;
- display current/default/declared value and description;
- preview diff and undo before saving.

Do not adopt its universal parser architecture. The upstream project has not had code pushed since 2022 and itself documents unsupported option types. It is a design reference, not a dependency.

### NiCo

Adopt:
- GUI and generated Nix visible side by side for advanced structural changes;
- strict preservation of user-owned free Nix;
- dry validation before activation;
- external-change guard and Git-aware workflow.

Improve the Nix-Brix idea by file ownership rather than marker ownership:

```text
krisNOS-config/modules/
├── krisncc-managed.nix   # only file krisNCC may regenerate
├── local-system.nix      # human-owned structural overrides
└── free.nix              # never rewritten by krisNCC
```

This avoids losing comments/formatting around marker blocks.

### MyNixOS

Adopt:
- module/import mental model;
- option inputs generated from Nix option types;
- fallback to raw Nix expression only in Advanced mode;
- clear distinction between reusable module and host configuration;
- broad type coverage as a design target, without pretending every exotic Nix type maps cleanly to a widget.

Do not make cloud/web configuration a requirement. GitHub is optional exchange/versioning; the machine works offline.

### NixNG

No code/runtime dependency. Useful lesson only: modules should stay small, structured and minimal by default. NixNG is currently container-oriented and cannot boot real hardware, so it is not a desktop base for krisNOS.

## Advanced Nix option editor

The future editor has two layers:

1. **Curated settings**: the structural choices useful on this one desktop. They have hand-reviewed widgets and validation.
2. **Advanced option browser**: searchable hierarchy from NixOS option metadata with type-aware widgets when safe; unsupported/complex values are shown read-only or require an explicit raw Nix expression.

Before saving, the UI shows both generated `krisncc-managed.nix` and a diff. Saving never implies build/apply. If `krisncc-managed.nix` changes externally while an edit session is open, the session is invalidated rather than overwriting the external change.

## Ownership model

1. **Foundations**: NixOS/krisNOS modules, changed rarely and rebuilt.
2. **Native mutable state**: NetworkManager, BlueZ, PipeWire/WirePlumber, CUPS, firewalld, Distrobox, Flatpak. krisNCC uses their native APIs/state.
3. **User software**: `nix profile` through `kris-app`; no system rebuild.
4. **Personal structural configuration**: `krisNOS-config`; sync is always manual. krisNCC edits only its owned module and shows a diff first.
5. **Free Nix**: never modified by krisNCC.

## Non-negotiable safety rules

- no background Git polling or auto-sync;
- Sync never implies Apply;
- no automatic rebuild after software installation;
- no direct arbitrary shell execution as root;
- no hidden krisNCC state that becomes a second source of truth;
- no generated config is activated before Nix evaluation/build succeeds;
- mutation backends are added only with narrow validation and tests.
