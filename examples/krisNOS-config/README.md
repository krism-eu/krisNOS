# krisNOS-config

Personal configuration for one krisNOS machine.

This repository is intentionally separate from `krisNOS` so a routine configuration sync never upgrades the framework or the control center.

## Rules

- Sync is manual only.
- Sync never implies Apply.
- No Wi-Fi passwords, VPN credentials, tokens, password hashes, Bluetooth keys or runtime databases are committed.
- `hardware-configuration.nix` may be tracked after it is generated on the real target; verify it before commit.

## First setup

1. Create the empty `krism-eu/krisNOS-config` repository.
2. Push this seed to it.
3. Generate the real hardware configuration on the target.
4. Run `nix flake lock` and commit `flake.lock`.
5. Point `kris-configctl` at the local clone (default `~/krisNOS-config`).
