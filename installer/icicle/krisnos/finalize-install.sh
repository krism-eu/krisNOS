#!/usr/bin/env bash
set -euo pipefail

src=/etc/nixos
[ -d "$src" ] || { echo "krisNOS finalize: $src mancante" >&2; exit 1; }
[ -f "$src/flake.nix" ] || { echo "krisNOS finalize: flake.nix mancante" >&2; exit 1; }
[ -f "$src/flake.lock" ] || { echo "krisNOS finalize: flake.lock mancante" >&2; exit 1; }
[ -f "$src/hardware-configuration.nix" ] || { echo "krisNOS finalize: hardware-configuration.nix mancante" >&2; exit 1; }

user_name=
user_uid=
user_gid=
user_home=
while IFS=: read -r name _ uid gid _ home _; do
  case "$home" in
    /home/*)
      if [ "$uid" -ge 1000 ] 2>/dev/null && [ "$uid" -lt 60000 ] 2>/dev/null; then
        user_name=$name
        user_uid=$uid
        user_gid=$gid
        user_home=$home
        break
      fi
      ;;
  esac
done < /etc/passwd

[ -n "$user_name" ] || { echo "krisNOS finalize: utente desktop non trovato" >&2; exit 1; }
[ -n "$user_home" ] || { echo "krisNOS finalize: home utente non trovata" >&2; exit 1; }

set -- "$src"/hosts/*
[ "$#" -eq 1 ] && [ -d "$1" ] \
  || { echo "krisNOS finalize: atteso un solo host in $src/hosts" >&2; exit 1; }
host_dir=$1

# kris-configctl historically expects the hardware file below hosts/<host>.
# Keep the generated file itself at the flake root for the installer import and
# add a tracked compatibility symlink after installation.
ln -s ../../hardware-configuration.nix "$host_dir/hardware-configuration.nix"

dst="$user_home/krisNOS-config"
[ ! -e "$dst" ] || { echo "krisNOS finalize: destinazione già esistente: $dst" >&2; exit 1; }

mkdir -p "$user_home"
mv "$src" "$dst"
ln -s "$dst" "$src"

# The finalizer is installation-only and must not become part of the editable
# personal configuration repository.
rm -f "$dst/finalize-install.sh"

# Start with a local Git history only. No remote is configured and no network
# access is performed; GitHub remains an explicit, optional later action.
git -C "$dst" init -b main >/dev/null
git -C "$dst" add --all
git -C "$dst" \
  -c user.name='krisNOS installer' \
  -c user.email='installer@localhost' \
  commit -m 'Initial installed krisNOS configuration' >/dev/null

chown -R "$user_uid:$user_gid" "$dst"
chown "$user_uid:$user_gid" "$user_home"

printf 'krisNOS configuration ready at %s for %s\n' "$dst" "$user_name"
