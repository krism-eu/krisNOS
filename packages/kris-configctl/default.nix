{
  writeShellApplication,
  writeShellScript,
  callPackage,
  git,
  nix,
  jq,
  coreutils,
  gnused,
  gawk,
  util-linux,
}:
let
  krisSystemActivate = callPackage ../kris-system-activate { };
  krisConfigctlImpl = writeShellScript "kris-configctl-impl" (builtins.readFile ./kris-configctl.sh);
in
writeShellApplication {
  name = "kris-configctl";
  runtimeInputs = [
    git
    nix
    jq
    coreutils
    gnused
    gawk
    util-linux
    krisSystemActivate
  ];
  text = ''
    cmd="''${1:-}"
    repo="''${KRISOS_CONFIG_REPO:-$HOME/krisNOS-config}"
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/krisos"
    before_head=""

    case "$cmd" in
      init|fetch|pull|push|sync|apply|prepare-apply|record-applied|system-package-add|system-package-remove|cleanup-profile|cleanup-system|cleanup-store)
        mkdir -p "$state_dir"
        if [ -d "$repo/.git" ]; then
          lock_file="$repo/.git/kris-configctl.lock"
        else
          lock_file="$state_dir/kris-configctl.lock"
        fi
        exec 9>"$lock_file"
        if ! flock -n 9; then
          printf '%s\n' "kris-configctl: un'altra operazione di modifica è già in corso." >&2
          exit 75
        fi
        ;;
    esac

    case "$cmd" in
      system-package-add|system-package-remove)
        if [ -d "$repo/.git" ]; then
          before_head="$(git -C "$repo" rev-parse --verify HEAD 2>/dev/null || true)"
        fi
        ;;
    esac

    set +e
    ${krisConfigctlImpl} "$@"
    rc=$?
    set -e

    if [ "$rc" -ne 0 ]; then
      case "$cmd" in
        system-package-add|system-package-remove)
          after_head=""
          if [ -d "$repo/.git" ]; then
            after_head="$(git -C "$repo" rev-parse --verify HEAD 2>/dev/null || true)"
          fi
          if [ -n "$before_head" ] && [ -n "$after_head" ] && [ "$after_head" != "$before_head" ]; then
            printf 'kris-configctl: configurazione salvata nel commit %s, ma build/attivazione/registrazione non è stata completata. Il commit resta nel repo locale; controllare lo stato prima di riprovare.\n' "$after_head" >&2
          fi
          ;;
      esac
    fi

    exit "$rc"
  '';
}
