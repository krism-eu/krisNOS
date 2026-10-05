# krisNOS mutability matrix — v0.6

The firewall is not the mutable layer; it is only one provider. The design rule is:

> Put in Nix only the foundations and capabilities that should not disappear accidentally. Keep normal desktop administration mutable through the native owner whenever possible.

## Foundation: declarative / rare rebuild

These remain Nix-owned:

- bootloader, filesystems, initrd, kernel and firmware;
- AMD graphics stack and hardware integration;
- Plasma/SDDM/Wayland and xdg portals;
- D-Bus, Polkit and the security/integration skeleton;
- availability of NetworkManager, PipeWire/WirePlumber, BlueZ, CUPS and firewalld;
- Nix itself and KrisOS helper packages;
- the primary desktop user/group foundations;
- components whose installation changes PAM, udev, kernel modules or global system integration.

A rebuild here is intentional and rare.

## Fast mutable administration: no NixOS rebuild

| Domain | Native owner / API | Typical mutable actions | Persistence owner |
| --- | --- | --- | --- |
| Nix applications | user `nix profile` | install/remove/upgrade/rollback | Nix user profile |
| Flatpak | Flatpak | install/remove/remotes/update | Flatpak |
| Network | NetworkManager | Wi-Fi/Ethernet/VPN/DNS/connections/radios | NetworkManager |
| Firewall | firewalld | on/off/zones/services/ports/rules | firewalld + tiny Kris policy only where Nix would reassert state |
| Bluetooth | BlueZ + rfkill | radio/pair/trust/remove/connect | BlueZ/systemd-rfkill |
| Printing | CUPS | add/remove/default/pause/resume/options | CUPS |
| Audio | PipeWire/WirePlumber | volume/mute/default device/profile/routing | WirePlumber/user state |
| Power | power-profiles-daemon | current power profile | daemon/runtime policy |
| Desktop | Plasma/KConfig | theme/panels/input/app settings | user config |
| Distrobox | Distrobox + hidden rootless Podman engine | create/remove/enter/upgrade/export apps | Distrobox/Podman user state |
| Users/passwords | normal system tools when allowed | password and selected mutable account state | system account DB |

krisNCC should use native D-Bus/APIs first. A Kris-owned state file is allowed only for a setting that otherwise gets reasserted by Nix and has no suitable native persistence mechanism.

## Settings that need classification before implementation

Some settings look like ordinary GUI settings but NixOS may own their generated files. Examples include hostname, global locale/timezone, service boot enablement, PAM/security policy, kernel parameters and some udev/systemd configuration.

For each such setting we choose one of three policies:

1. **foundation** — change through Nix and rebuild;
2. **native mutable** — stop declaring its value in Nix and let the upstream service own it;
3. **Kris mutable policy** — keep the capability in Nix but persist a small allowlisted value under `/var/lib/krisos` and re-apply it safely after activation/boot.

Never solve this with a generic writable overlay over `/nix/store` or arbitrary `/etc` edits.

## GUI consequence

The GUI can present one coherent “Sistema” section even though the backend is split:

- Network -> NetworkManager
- Bluetooth -> BlueZ
- Audio -> PipeWire/WirePlumber
- Printing -> CUPS
- Firewall -> firewalld
- Power -> power-profiles-daemon
- Software -> Nix profile / Flatpak
- Environments -> Distrobox
- Structural base -> guarded NixOS build/switch

The implementation detail should be invisible to the user.
