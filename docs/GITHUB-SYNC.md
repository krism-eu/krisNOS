# GitHub configuration exchange

## Active repositories

### `krism-eu/krisNOS`

Framework repository:

- reusable NixOS modules;
- helper packages;
- ISO/VM tooling;
- krisNCC source/integration contracts;
- defaults and tests.

### `krism-eu/krisNOS-config`

Personal machine configuration. Its `flake.nix` imports `krisNOS` as a GitHub input and follows the framework's `nixpkgs` input.

The dependency is intentionally one-way:

```text
krisNOS-config  --->  krisNOS
```

`krisNOS` must never import or require the personal repository to boot/build its generic framework.

## Goal

GitHub is a versioned exchange/control point, **not a boot dependency**. The installed PC always has a complete local checkout and continues to work offline.

This enables both directions:

1. edit locally (including future krisNCC editors) -> commit -> push;
2. edit the same configuration on GitHub/another trusted workstation/assistant workflow -> PC fetches -> validates -> applies.

No GitHub Actions, release pipeline or hosted build is required. There is no automatic synchronization: GitHub is contacted only after an explicit user action in krisNCC or `kris-configctl`.

## Local checkout

Default location:

```text
~/krisNOS-config
```

Initialize it with:

```text
kris-configctl init
```

The default remote is `https://github.com/krism-eu/krisNOS-config.git`; it can be overridden with an explicit URL or `KRISOS_CONFIG_REMOTE`.

The checkout is user-owned. Root is used only for the final NixOS build/switch.

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
- build/switch remain separate user-visible actions.

## Apply path

```text
GitHub
  ↓ explicit fetch/sync
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

```text
Configurazione
────────────────────────────
Locale       a83c19d
GitHub       a83c19d     ✓ Allineato
Applicata    a83c19d     ✓

[ Controlla ] [ Mostra diff ]
[ Sincronizza ]

[ Valida ] [ Costruisci ] [ Applica ]
```

**Sincronizza does not mean Applica.** Downloading, validating, building and activating remain distinct operations.

## Secrets and runtime state

Do **not** version `/var/lib`, `/etc/NetworkManager/system-connections`, BlueZ pairing keys, VPN credentials, Wi-Fi PSKs, password hashes, private keys or tokens.

The Git repository stores source configuration and explicitly exportable/sanitized preferences. Runtime databases remain local unless a dedicated encrypted secrets mechanism is deliberately introduced later.

A private GitHub repository is still not a reason to commit plaintext credentials.

## Authentication

Use ordinary Git authentication. `kris-configctl` must never store GitHub tokens in Nix source or in its own state file.

## Non-automatic by design

Do not add a `systemd.timer`, cron job, NetworkManager dispatcher, login hook, boot hook, background poller or automatic `git pull`. Every fetch/sync/apply remains an explicit action.
