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
| Bluetooth radio | BlueZ/rfkill via `kris-runtimectl` | No |
| Printers/queues | CUPS | No |
| Audio/routing | PipeWire/WirePlumber | No |
| Power profile | power-profiles-daemon | No |
| Runtime services/logs | systemd | No |
| Curated structural settings | `krisNOS-config/modules/krisncc-managed.nix` | Yes |
| Kernel/boot/base integration | NixOS | Yes |

## Privilege split

- `kris-app` is user-only and refuses root.
- `kris-configctl diff/validate/build` are user operations.
- `kris-runtimectl` and `kris-system-activate` are small fixed root helpers with validated interfaces.
- The initial personal-host policy deliberately puts `kris` in passwordless `wheel`. krisNCC therefore calls only those fixed helpers through non-interactive `sudo -n`; it never constructs or executes an arbitrary root shell command.
- This is an ergonomics/code-quality restriction, not a security boundary: while `wheelNeedsPassword = false`, any process running as `kris` can obtain root through sudo.
- `kris-configctl apply` captures the Git commit before build, pins inputs through the lock, protects the toplevel with a temporary GC root, rechecks HEAD/clean state, activates through `kris-system-activate`, then records commit+toplevel only after the switch succeeds.

## Stable output

- `kris-runtimectl status --json`: schema 1.
- `kris-configctl status --json`: schema 2, including last-applied commit metadata validated against `/run/current-system`.
- `kris-app list --json`: currently follows the Nix profile JSON shape (`version` + `elements`).

Before the Software page becomes a stable public contract, package search/list/history should be normalized behind krisNCC rather than coupling QML permanently to experimental Nix JSON.

## Bluetooth scope

Bluetooth is intentionally low-priority: krisNCC only needs a reliable ON/OFF state. BlueZ `Powered` is authoritative for controller power and rfkill remains authoritative for hard/soft blocks. Pairing/device management is deferred until a real need appears.

## Distrobox rule

The UI exposes environments, not raw container-engine concepts. Operations use Distrobox commands with validated names/image references. Raw Podman image/network/container management is intentionally not part of normal krisNCC.

## Failure rule

A failed backend command must leave native state as the source of truth, surface a useful message and refresh the affected view. No operation may silently manufacture a second krisNCC state to pretend success.
