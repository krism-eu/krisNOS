# v0.4 changes

- Corrected the architecture: firewall is one mutable provider, not the definition of the mutable layer.
- Added a full mutability matrix for NetworkManager, BlueZ, CUPS, PipeWire/WirePlumber, firewalld, power profiles, software and desktop state.
- Defined three policies for system settings: foundation, native mutable, or narrow Kris mutable policy.
- Added `kris-configctl`, a local Git configuration exchange helper with JSON status, safe fetch/pull/push/sync, validation, build and apply.
- Git sync is fast-forward-only and refuses dirty/diverged trees; no automatic merge, reset or force-push.
- Defined GitHub as an optional control/exchange point, never a boot dependency.
- Recommended two repos: `krisNOS` framework and a personal `krisNOS-config` desired-state repo.
- Explicitly excluded secrets and daemon databases from automatic Git export.
