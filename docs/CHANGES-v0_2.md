# Changes v0.1 -> v0.2

1. **Flake / hardware file**: removed `hosts/topton-fu02/hardware-configuration.nix` from `.gitignore`; `krisos-topton` and the `top-level-system` check exist only when the file exists, so `nix flake check` works on a fresh clone. README now says to `git add` the file.
2. **Live profile**: autologin, throwaway password, passwordless sudo (live only); README clarifies that `iso-installer` is the base installer image.
3. **kris-app**: root guard; `add --unfree`; `upgrade` with unfree allowed (`--impure`); `remove` accepts element names only (names validated); `help`.
4. **kris-runtimectl / runtime layer**:
   - `get_value` is fail-safe (defaults to `on`) and no longer aborts the script on a missing/corrupt value;
   - `status` and new `is-on` are read-only (no more writes as a normal user);
   - state is rewritten from the allowlist only (legacy keys dropped);
   - BLUETOOTH removed from `runtime.conf` (single owner); `bluetooth on|off` is an immediate rfkill toggle, `status` shows live state;
   - `krisos-runtime-init` removed (defaults live only in `kris-runtimectl`);
   - `firewalld.service` gets `ExecCondition` so FIREWALL=off survives rebuilds/restarts;
   - `krisos-runtime-apply` uses `RemainAfterExit`; the `gnugrep` dependency was dropped.

Tested here: both helper scripts with stubbed `systemctl`/`rfkill`/`nix`, as root and as an unprivileged user (state handling, corrupt/missing state, argument validation, exit codes). Not tested here (no Nix): all `.nix` files, shellcheck run by `writeShellApplication`, the `ExecCondition` behaviour under real systemd.
