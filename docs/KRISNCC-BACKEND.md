# krisNCC backend contract

## Principle

Every GUI action maps to one explicit backend and one ownership domain. krisNCC orchestrates native components; it does not become a second implementation of them.

| GUI function | Backend | Rebuild? |
|---|---|---:|
| Nix user apps | `nix profile` via `kris-app` | No |
| Try Nix app | `nix run` via `kris-app` | No |
| Flatpak apps | `flatpak` | No |
| Distrobox environments | Distrobox; engine hidden | No |
| Firewall rules/zones | firewalld | No |
| Firewall master state | `kris-runtimectl` | No |
| Wi-Fi/VPN/DNS | NetworkManager | No |
| Bluetooth pairing/devices | BlueZ | No |
| Bluetooth radio | BlueZ/rfkill via `kris-runtimectl` | No |
| Printers/queues | CUPS | No |
| Audio/routing | PipeWire/WirePlumber | No |
| Power profile | power-profiles-daemon | No |
| Runtime services/logs | systemd | No |
| Curated structural settings | `krisNOS-config/modules/krisncc-managed.nix` | Yes |
| Kernel/boot/base integration | NixOS | Yes |

## Privilege split

- `kris-app` is user-only and refuses root.
- `kris-configctl diff/validate/build` are user operations. Build uses `nix build --no-link`; it does not need root and does not change the running system.
- `kris-runtimectl` is a small root helper with an explicit command allowlist. The bootstrap invokes it through resolved `pkexec` arguments for Bluetooth/firewall mutations; no shell string is executed.
- Final NixOS activation will be exposed only after a dedicated narrow Polkit path is in place. The GUI must not hide `sudo` inside a background process.

## Stable output

- `kris-runtimectl status --json`: schema 1.
- `kris-configctl status --json`: schema 2, including last-applied commit metadata.
- `kris-app list --json`: currently follows the Nix profile JSON shape (`version` + `elements`).

Before the Software page becomes a stable public contract, package search/list/history should be normalized behind krisNCC rather than coupling QML permanently to experimental Nix JSON.

## Distrobox rule

The UI exposes environments, not raw container-engine concepts. Operations use Distrobox commands with validated names/image references. Raw Podman image/network/container management is intentionally not part of normal krisNCC.

## Failure rule

A failed backend command must leave native state as the source of truth, surface a useful message and refresh the affected view. No operation may silently manufacture a second krisNCC state to pretend success.
