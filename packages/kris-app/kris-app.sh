set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  kris-app search [--json] <text>
  kris-app add [--unfree] <nixpkgs-attribute>
  kris-app run [--unfree] <nixpkgs-attribute>
  kris-app remove <element-name>
  kris-app list [--json]
  kris-app upgrade [--unfree] [--dry-run]
  kris-app history
  kris-app rollback

Examples:
  kris-app search --json vlc
  kris-app add vlc
  kris-app run kdePackages.kcalc
  kris-app add --unfree spotify
  kris-app list
  kris-app remove vlc

Notes:
  - Runs as your own user, never as root.
  - `run` uses `nix run`: it does not add the package to your profile.
  - Unfree packages need an explicit --unfree on `add`/`run`.
  - `remove` takes the element name shown by `kris-app list`.
  - `upgrade --dry-run` is used only when the installed Nix exposes that
    capability; otherwise it exits safely without changing the profile.
USAGE
}

valid_attr() {
  case "$1" in
    (*[!A-Za-z0-9._+@-]*|'') return 1 ;;
    (*) return 0 ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  -h|--help|help) usage; exit 0 ;;
esac

# This helper manages the user's profile; root would silently target root's profile.
if [ "$(id -u)" -eq 0 ]; then
  echo "kris-app: non eseguire come root (usa il tuo utente)" >&2
  exit 77
fi

case "$cmd" in
  search)
    shift
    json=0
    if [ "${1:-}" = "--json" ]; then json=1; shift; fi
    [ "$#" -ge 1 ] || { usage >&2; exit 2; }
    if [ "$json" -eq 1 ]; then
      exec nix search --json nixpkgs "$*"
    fi
    exec nix search nixpkgs "$*"
    ;;
  add|run)
    action="$cmd"
    shift
    unfree=0
    if [ "${1:-}" = "--unfree" ]; then unfree=1; shift; fi
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    valid_attr "$1" || { echo "kris-app: attributo Nix non valido" >&2; exit 2; }
    if [ "$unfree" -eq 1 ]; then
      export NIXPKGS_ALLOW_UNFREE=1
      if [ "$action" = add ]; then
        exec nix profile add --impure "nixpkgs#$1"
      fi
      exec nix run --impure "nixpkgs#$1"
    fi
    if [ "$action" = add ]; then
      exec nix profile add "nixpkgs#$1"
    fi
    exec nix run "nixpkgs#$1"
    ;;
  remove)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    valid_attr "$2" || { echo "kris-app: nome elemento non valido" >&2; exit 2; }
    case "$2" in
      -*) echo "kris-app: opzioni non ammesse come nome elemento" >&2; exit 2 ;;
      (*[!0-9]*) ;;
      (*) echo "kris-app: indici non supportati, usa il nome elemento" >&2; exit 2 ;;
    esac
    exec nix profile remove -- "$2"
    ;;
  list)
    if [ "${2:-}" = "--json" ]; then
      [ "$#" -eq 2 ] || { usage >&2; exit 2; }
      exec nix profile list --json
    fi
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    exec nix profile list
    ;;
  upgrade)
    shift
    dry_run=0
    unfree=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --dry-run) dry_run=1 ;;
        --unfree) unfree=1 ;;
        *) usage >&2; exit 2 ;;
      esac
      shift
    done

    if [ "$dry_run" -eq 1 ]; then
      upgrade_help="$(nix profile upgrade --help 2>&1 || true)"
      case "$upgrade_help" in
        *--dry-run*) set -- --all --dry-run ;;
        *)
          echo "kris-app: questa versione di Nix non supporta un'anteprima sicura di 'profile upgrade'; nessuna modifica eseguita" >&2
          exit 69
          ;;
      esac
    else
      set -- --all
    fi

    if [ "$unfree" -eq 1 ]; then
      export NIXPKGS_ALLOW_UNFREE=1
      exec nix profile upgrade --impure "$@"
    fi

    exec nix profile upgrade "$@"
    ;;
  history)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    exec nix profile history
    ;;
  rollback)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    exec nix profile rollback
    ;;
  *) usage >&2; exit 2 ;;
esac
