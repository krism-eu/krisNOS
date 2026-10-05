# Next integration pass

When the previous personal NixOS configuration is available:

- diff it module-by-module against this scaffold
- import only hardware/boot choices that still make sense
- identify packages that should move from `environment.systemPackages` to the personal profile
- identify service settings that can become runtime state instead of Nix state
- verify Topton FU02 hardware configuration and filesystem layout
- decide installation path and whether to retain Calamares or use the native NixOS installer flow
- package or port krisNCC to Qt/Kirigami on NixOS
- add JSON contracts and focused tests for `kris-app` and `kris-runtimectl`
- run a real `nix flake check`, VM boot, then ISO boot before touching the physical installation

## Known item to verify before first install

- Re-test the NixOS 26.05 firewalld backend reverse-path-filter handling. A 2026 upstream issue reports swapped strict/loose `rp_filter` values. Do not call the firewall layer final until the pinned revision is checked or locally corrected.

## Review points completed through v0.4

- graphical Italian keyboard layout is explicit;
- systemd-boot entries are capped (default 5);
- `system.stateVersion` is host/profile-owned, not buried in the reusable core module;
- automatic GC is disabled until krisNCC owns an explicit, understandable retention policy;
- the custom PRINTING toggle and boot apply service were removed: CUPS owns printing state, reducing custom synchronization.

## Review points still open

- Verify whether `noto-fonts-emoji` (now `noto-fonts-color-emoji`) and `nixfmt-rfc-style` (now `nixfmt`) are still accepted aliases in the pinned 26.05; `check.sh` runs `nix fmt -- --check`, so run `nix fmt` once first.
- `iso-installer` is a text installer image with this configuration on top; decide whether to move to a Calamares/Plasma live image.
- Verify first on real Nix: the `ExecCondition` guard on firewalld, and the Flatpak/Podman first-run flow (no Flathub remote is added yet).


## v0.4 next design work

- classify additional quick system settings (hostname, timezone/locale, startup policies) into foundation/native/Kris-policy;
- define read/write JSON contracts for NetworkManager, BlueZ, CUPS, PipeWire/WirePlumber and power profiles;
- decide which portable, non-secret preferences can be exported into `krisNOS-config`;
- keep credentials and native runtime databases local;
- integrate `kris-configctl` into a future krisNCC Config/Sync page;
- create the actual GitHub repositories only after the local layout and first Nix VM test are accepted.
