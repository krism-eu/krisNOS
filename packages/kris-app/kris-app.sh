set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  kris-app search <text>
  kris-app add [--unfree] <nixpkgs-attribute>
  kris-app remove <profile-element-name>
  kris-app list [--json]
  kris-app upgrade [--dry-run]
  kris-app history
  kris-app rollback

Examples:
  kris-app add vlc
  kris-app add kdePackages.kcalc
  kris-app add --unfree spotify
  kris-app list
  kris-app remove vlc

Notes:
  - Runs as your own user, never as root.
  - Unfree packages need an explicit --unfree on `add` (nix profile ignores
    the system allowUnfree setting). `upgrade` then re-evaluates what you
    already installed with unfree allowed.
  - `remove` takes the element name shown by `kris-app list`
    (this helper does not accept numeric indices).
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
  -h|--help|help)
    usage
    exit 0
    ;;
esac

# This helper manages the *user's* profile; as root it would silently touch
# root's profile instead.
if [ "$(id -u)" -eq 0 ]; then
  echo "kris-app: non eseguire come root (usa il tuo utente)" >&2
  exit 77
fi

case "$cmd" in
  search)
    shift
    [ "$#" -ge 1 ] || { usage >&2; exit 2; }
    exec nix search nixpkgs "$*"
    ;;
  add)
    shift
    unfree=0
    if [ "${1:-}" = "--unfree" ]; then
      unfree=1
      shift
    fi
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    valid_attr "$1" || { echo "kris-app: attributo Nix non valido" >&2; exit 2; }
    if [ "$unfree" -eq 1 ]; then
      export NIXPKGS_ALLOW_UNFREE=1
      exec nix profile add --impure "nixpkgs#$1"
    fi
    exec nix profile add "nixpkgs#$1"
    ;;
  remove)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    valid_attr "$2" || { echo "kris-app: nome elemento non valido" >&2; exit 2; }
    case "$2" in
      (*[!0-9]*) ;;
      (*) echo "kris-app: indici non supportati, usa il nome (kris-app list)" >&2; exit 2 ;;
    esac
    exec nix profile remove "$2"
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
    export NIXPKGS_ALLOW_UNFREE=1
    if [ "${2:-}" = "--dry-run" ]; then
      [ "$#" -eq 2 ] || { usage >&2; exit 2; }
      exec nix profile upgrade --impure --all --dry-run
    fi
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    exec nix profile upgrade --impure --all
    ;;
  history)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    exec nix profile history
    ;;
  rollback)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    exec nix profile rollback
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
