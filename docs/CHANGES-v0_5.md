# Changes in prototype v0.5

- Distrobox is now the user-facing container feature.
- Podman stays only as a rootless implementation engine and disappears from the intended krisNCC navigation.
- Added rootless UID/GID mappings to the target/live user configurations.
- Formalized two Git repositories: framework (`krisNOS`) and personal config (`krisNOS-config`).
- GitHub sync is explicitly manual-only: no timer, boot pull, background polling, automatic merge or automatic apply.
- Added a standalone `krisNOS-config-seed` scaffold for the personal repository.
- Updated krisNCC backend contract and mutability matrix.
