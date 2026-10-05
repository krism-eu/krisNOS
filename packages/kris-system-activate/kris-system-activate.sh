set -euo pipefail

usage() {
  printf 'Uso: kris-system-activate /nix/store/<nixos-system-toplevel>\n' >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
[ "$(id -u)" -eq 0 ] || {
  echo "kris-system-activate: privilegi amministrativi richiesti" >&2
  exit 77
}

requested="$1"
canonical="$(realpath -e -- "$requested")" || {
  echo "kris-system-activate: toplevel inesistente" >&2
  exit 2
}

[ "$requested" = "$canonical" ] || {
  echo "kris-system-activate: il toplevel deve essere un percorso canonico" >&2
  exit 2
}

base="${canonical#/nix/store/}"
case "$canonical" in
  /nix/store/*) ;;
  *)
    echo "kris-system-activate: toplevel fuori da /nix/store" >&2
    exit 2
    ;;
esac

if [[ ! "$base" =~ ^[0-9abcdfghijklmnpqrsvwxyz]{32}-nixos-system-[^/]+$ ]]; then
  echo "kris-system-activate: percorso non riconosciuto come toplevel NixOS" >&2
  exit 2
fi

[ -x "$canonical/bin/switch-to-configuration" ] || {
  echo "kris-system-activate: switch-to-configuration mancante" >&2
  exit 2
}

nix-env --profile /nix/var/nix/profiles/system --set "$canonical"
"$canonical/bin/switch-to-configuration" switch
