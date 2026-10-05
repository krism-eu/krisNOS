# Reuse of current krisCC

| Current krisCC area | krisNCC | Decision |
| --- | --- | --- |
| Dashboard | Dashboard | reuse UI/model ideas |
| System resources | Dashboard/System | reuse with Nix-specific additions |
| Services | System runtime | keep reduced start/stop/restart/log view |
| DNF/RPM software | Nix Software | remove backend, replace completely |
| Flatpak | Software | reuse |
| Podman page | Distrobox | replace user-facing feature |
| `rk` Recovery | Nix generations | remove backend, simplify |
| bootc status/update | Nix config/generations | remove |
| personal commands | Tools | reuse |
| external backup launcher | Tools/System | reuse if still desired |
| GitHub config sync | Configuration | new |
| Nix option editor | Configuration/Advanced | new, selective |

The Qt/Kirigami visual shell is the asset to preserve. Fedora-specific package/recovery/deployment backends are not.
