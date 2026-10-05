# Initial decisions

1. Base: upstream NixOS 26.05, not a deep Xinux/SnowflakeOS fork.
2. Xinux/SnowflakeOS are references for UX, ISO layout and graphical software management.
3. No dependency on deprecated `nixos-generators`; use native NixOS image builders.
4. Flake is a build/pinning wrapper. NixOS modules themselves contain no flake-specific arguments and remain reusable by a traditional `configuration.nix`.
5. No Home Manager requirement.
6. No generic writable overlay over `/etc` or `/nix/store`.
7. Applications go to the user's Nix profile by default.
8. System daemons needed for desktop integration are declared once in the base, then manipulated through their runtime APIs/state.
9. No SSH server by default.
10. Plasma 6 Wayland is primary; XWayland remains available for compatibility.
11. Base package list remains intentionally small.
12. Git hosting/CI is optional: local `nix flake check`, VM and ISO builds are first-class.
13. Firewalld is used through the supported NixOS backend for now because it preserves NixOS service integrations while exposing firewalld's runtime API; its known 26.05 reverse-path-filter issue is an explicit pre-install verification item.
14. `hardware-configuration.nix` is tracked in Git (not ignored): flakes cannot see ignored/untracked files. `krisos-topton` and its check are exposed only when the file exists.
15. Live profile: autologin + throwaway password + passwordless sudo, live/VM only.
16. Kris-owned persistent runtime state is intentionally tiny: `runtime.conf` persists only `FIREWALL`. Printing remains native CUPS state; Bluetooth remains rfkill/BlueZ state.
17. `kris-runtimectl` owns the firewall state default (fail-safe `on`); `firewalld.service` is guarded by `ExecCondition` so boot/rebuild cannot silently re-enable a firewall the user turned off.
18. `kris-app` refuses root; unfree is opt-in per package (`add --unfree`), `upgrade` evaluates the profile with unfree allowed; `remove` takes names only.
19. `system.stateVersion` is host/profile-owned. Reusable modules must not silently impose it on existing systems.
20. Automatic Nix GC is disabled until retention is surfaced explicitly in krisNCC; systemd-boot menu entries are capped separately (default 5).

21. Distrobox replaces raw Podman as the user-facing container feature. Podman remains enabled only as a rootless engine underneath Distrobox; krisNCC does not expose a general Podman administration page.
22. GitHub configuration exchange is always manual and optional. There is no timer, boot-time pull, background sync, automatic apply, or dependency on GitHub availability.
23. The framework and personal configuration use separate repositories: `krisNOS` and `krisNOS-config`. This prevents an ordinary personal-config sync from silently importing framework/control-center development.
24. `krisNOS-config` contains no plaintext secrets or runtime databases. It stores only source configuration and explicitly exportable/sanitized preferences.
