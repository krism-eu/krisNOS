# GitHub configuration exchange — v0.5 design

## Goal

GitHub is a versioned exchange/control point, **not a boot dependency**. The installed PC always has a complete local checkout and continues to work offline.

This enables both directions:

1. edit locally (including future krisNCC editors) -> commit -> push;
2. edit the same configuration on GitHub/another trusted workstation/assistant workflow -> PC fetches -> validates -> applies.

No GitHub Actions, release pipeline or hosted build is required. There is also no automatic synchronization: GitHub is contacted only after an explicit user action in krisNCC or `kris-configctl`.

## Recommended two-repository model

### `krism-eu/krisNOS`

Project/framework repository:

- reusable NixOS modules;
- helper packages;
- ISO/VM tooling;
- krisNCC integration contracts;
- defaults and tests.

Changes rarely.

### `krism-eu/krisNOS-config` (personal repository)

The machine's desired configuration:

```text
krisNOS-config/
├── configuration.nix          # classic entry point, if used
├── flake.nix / flake.lock     # optional reproducible wrapper
├── hosts/
│   └── topton-fu02/
├── modules/
│   ├── local-base.nix
│   └── local-policy.nix
├── krisncc/
│   └── preferences.json       # only safe, portable preferences
└── .gitignore
```

The system may support both classic `configuration.nix` and a flake wrapper. Flakes are useful for pinning/reproducibility but should not be required for the conceptual split.

## Local checkout

Default proposed location:

```text
~/krisNOS-config
```

It is user-owned and normal Git tooling can edit it. Root is used only for the final NixOS activation.
`nixos-rebuild` is supplied by the running NixOS system; the helper does not create or publish a separate system image.

Do not make `/etc/nixos` the Git working tree if that forces routine editing as root. `nixos-rebuild` can be pointed at another configuration path.

## Safe sync state machine

`kris-configctl sync` never performs an arbitrary merge.

```text
remote ahead only -> fetch + fast-forward local
local ahead only  -> push
same              -> no-op
dirty tree        -> STOP
diverged history  -> STOP
```

Hard rules:

- no `git reset --hard`;
- no force push;
- no automatic conflict resolution;
- no apply from a dirty checkout;
- no remote code is activated before Nix evaluation succeeds;
- ideally build before switch for important structural changes.

## Apply path

```text
GitHub
  ↓ fetch
local checkout
  ↓ fast-forward only
Nix evaluation
  ↓
NixOS build
  ↓
explicit Apply
  ↓
nixos-rebuild switch
  ↓
record deployed Git commit
```

Rollback remains a NixOS generation operation. Git answers “which configuration produced this?”; Nix generations answer “which built system do I boot/switch to?”.

## krisNCC page

Future page/card:

```text
Configurazione
────────────────────────────
Locale       a83c19d
GitHub       a83c19d     ✓ Allineato
Applicata    a83c19d     ✓

[ Sincronizza ]  [ Verifica ]  [ Applica ]

Modifiche locali: nessuna
```

If remote is newer:

```text
GitHub ha 2 commit nuovi
[ Mostra modifiche ] [ Scarica ]
```

Downloading and applying remain separate actions by default.

## Secrets and runtime state

Do **not** blindly version `/var/lib`, `/etc/NetworkManager/system-connections`, BlueZ pairing keys, VPN credentials, Wi-Fi PSKs, password hashes or tokens.

The Git repository stores source configuration and explicitly exportable/sanitized preferences. Runtime databases remain local unless a dedicated encrypted secrets mechanism is deliberately introduced later.

A private GitHub repository is still not a reason to commit plaintext credentials.

## Authentication

Use ordinary Git authentication (preferably an SSH key bound to the user's GitHub account or another narrow credential). `kris-configctl` must never store GitHub tokens in Nix source or in its own state file.


## Non-automatic by design

Do not add a `systemd.timer`, cron job, NetworkManager dispatcher, login hook, boot hook, background poller or automatic `git pull`. The configuration page may remember whether the GitHub integration is shown/enabled in the UI, but every fetch/sync/apply remains an explicit action.
