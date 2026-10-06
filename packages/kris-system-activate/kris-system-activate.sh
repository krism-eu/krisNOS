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

profile="/nix/var/nix/profiles/system"
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

current_link="$(readlink -- "$profile")" || {
  echo "kris-system-activate: profilo di sistema non leggibile" >&2
  exit 2
}
current_name="${current_link##*/}"
if [[ ! "$current_name" =~ ^system-([0-9]+)-link$ ]]; then
  echo "kris-system-activate: generazione corrente non riconoscibile" >&2
  exit 2
fi
current_generation="${BASH_REMATCH[1]}"
current_toplevel="$(realpath -e -- "$profile")" || {
  echo "kris-system-activate: toplevel corrente non risolvibile" >&2
  exit 2
}

if [ "$current_toplevel" = "$canonical" ]; then
  echo "kris-system-activate: la generazione richiesta è già attiva"
  exit 0
fi

target_generation=""
for link in /nix/var/nix/profiles/system-*-link; do
  [ -L "$link" ] || continue
  name="${link##*/}"
  [[ "$name" =~ ^system-([0-9]+)-link$ ]] || continue
  generation="${BASH_REMATCH[1]}"
  (( 10#$generation < 10#$current_generation )) || continue
  candidate="$(realpath -e -- "$link")" || continue
  [ "$candidate" = "$canonical" ] || continue
  if [ -z "$target_generation" ] || (( 10#$generation > 10#$target_generation )); then
    target_generation="$generation"
  fi
done

[ -n "$target_generation" ] || {
  echo "kris-system-activate: il toplevel richiesto non appartiene a una generazione precedente" >&2
  exit 2
}

# Il bootloader NixOS enumera le generazioni dal profilo system, quindi il
# profilo deve puntare alla generazione di destinazione prima dello switch.
# In caso di errore ripristiniamo sia il profilo sia, per quanto possibile,
# lo stato runtime/bootloader della generazione da cui siamo partiti.
nix-env --profile "$profile" --switch-generation "$target_generation"

if "$canonical/bin/switch-to-configuration" switch; then
  echo "kris-system-activate: rollback applicato alla generazione $target_generation"
  exit 0
else
  activation_status=$?
fi

echo "kris-system-activate: attivazione fallita; ripristino la generazione $current_generation" >&2
recovery_failed=0

if ! nix-env --profile "$profile" --switch-generation "$current_generation"; then
  echo "kris-system-activate: ERRORE: impossibile ripristinare il profilo precedente" >&2
  recovery_failed=1
fi

if [ "$recovery_failed" -eq 0 ] && ! "$current_toplevel/bin/switch-to-configuration" switch; then
  echo "kris-system-activate: ERRORE: impossibile riattivare completamente il sistema precedente" >&2
  recovery_failed=1
fi

if [ "$recovery_failed" -ne 0 ]; then
  echo "kris-system-activate: ripristino incompleto; riavviare scegliendo manualmente la generazione precedente" >&2
  exit 70
fi

echo "kris-system-activate: sistema precedente ripristinato dopo il fallimento" >&2
exit "$activation_status"
