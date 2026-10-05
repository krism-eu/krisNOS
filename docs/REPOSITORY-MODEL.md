# Repository model — v0.5

## Repositories

### `krism-eu/krisNOS`
Framework repository. It contains reusable NixOS modules, helper packages, build/VM/ISO tooling and the krisNCC backend contracts. It changes when the platform changes.

### `krism-eu/krisNOS-config`
Personal configuration repository. It contains only the desired configuration for the installed machine plus explicitly safe krisNCC preferences. It is the exchange point between the local PC, GitHub edits and assistant-assisted work.

Keeping them separate is a safety boundary: pressing **Sincronizza configurazione** must not also update the framework or krisNCC implementation.

## Manual-only synchronization

There is deliberately no systemd timer, path unit, boot hook, cron job or background process that contacts GitHub.

The UI offers an optional Configuration card:

```text
Configurazione GitHub                     [OFF/ON UI preference]

Locale      a83c19d
Remoto      e9384ab   2 commit nuovi
Applicata   a83c19d

[ Controlla ] [ Mostra differenze ] [ Sincronizza ]
                              [ Verifica ] [ Costruisci ] [ Applica ]
```

`Controlla`/`Sincronizza` are explicit network actions. `Applica` is a second deliberate action after validation/build; sync never activates a NixOS generation.

## Offline behaviour

The local checkout is complete. GitHub being unavailable has no effect on boot, login, installed applications or current configuration.

## Safety

- fast-forward only on pull;
- no force push;
- no automatic merge;
- dirty tree stops synchronization;
- diverged history stops synchronization;
- downloaded config is never auto-applied;
- a build must succeed before switch;
- credentials stay outside Git.

## Authentication

Use normal user Git authentication, preferably SSH. krisNCC does not own or persist a GitHub token.
