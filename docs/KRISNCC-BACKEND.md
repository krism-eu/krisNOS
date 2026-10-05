# krisNCC backend contract — first draft

## Principle

Every GUI action must map to one explicit backend and one ownership domain. No mixed ownership.

| GUI area | Backend | Rebuild? |
|---|---|---:|
| Personal Nix software | `nix profile` via `kris-app` | No |
| Flatpak | `flatpak` | No |
| Distrobox environments | Distrobox (Podman rootless engine hidden below) | No |
| Firewall rules/zones | firewalld | No |
| Firewall master state | `kris-runtimectl` | No |
| Wi-Fi/VPN/connections | NetworkManager | No |
| Bluetooth pairing / power policy | BlueZ (`powerOnBoot` in NixOS) | No |
| Bluetooth radio on/off | `kris-runtimectl bluetooth` (immediate rfkill, not persisted) | No |
| Printers / queues | CUPS | No |
| KDE/application settings | user config/native APIs | No |
| Kernel/boot/base services | NixOS configuration | Yes |
| Base upgrade | pinned Nixpkgs + NixOS rebuild | Yes |

## Privilege split

- `kris-app`: user only; refuses to run as root (exit 77). Unfree packages require `add --unfree`.
- `kris-runtimectl`: tiny root helper with a fixed allowlist. `status` and `is-on` are read-only and safe as a normal user; mutating commands exit 77 without root.
- Future GUI: prefer Polkit-mediated dedicated actions instead of unrestricted shell execution.
- NixOS rebuild remains a separate, deliberate administrative workflow.

## Output requirements for GUI integration

`kris-runtimectl status --json` now returns stable `schema: 1`; `kris-app list --json` delegates to Nix JSON. A later pass should define one normalized krisNCC-facing JSON schema for package search/list/history instead of exposing raw Nix output.


## Distrobox UI rule

The GUI exposes environments, not the container engine:

- create a distrobox from an allowlisted/explicit OCI image;
- list/start/stop/remove distroboxes;
- enter in Konsole;
- upgrade a selected distrobox;
- list/export graphical applications where Distrobox supports it.

Raw Podman images/networks/containers are not a normal krisNCC page. Podman remains replaceable implementation detail. Distrobox itself supports Podman, Docker or Lilipod, so this boundary avoids coupling the GUI to one engine.
