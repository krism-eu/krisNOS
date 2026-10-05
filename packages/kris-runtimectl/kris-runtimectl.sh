set -euo pipefail

STATE_DIR=/var/lib/krisos
STATE_FILE="$STATE_DIR/runtime.conf"

usage() {
  cat <<'USAGE'
Usage:
  kris-runtimectl status [--json]
  kris-runtimectl is-on firewall
  kris-runtimectl firewall on|off
  kris-runtimectl bluetooth on|off

Only the firewall master state is persisted in /var/lib/krisos/runtime.conf.
Bluetooth is an immediate rfkill toggle; systemd-rfkill owns radio persistence.
Mutating commands require root (normally through a narrow Polkit action).
USAGE
}

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "kris-runtimectl: privilegi amministrativi richiesti" >&2
    exit 77
  fi
}

ensure_state() {
  install -d -m 0755 "$STATE_DIR"
  if [ ! -e "$STATE_FILE" ]; then
    printf 'FIREWALL=on\n' > "$STATE_FILE"
    chmod 0644 "$STATE_FILE"
  fi
}

firewall_state() {
  value=""
  if [ -r "$STATE_FILE" ]; then
    value="$(sed -n 's/^FIREWALL=//p' "$STATE_FILE" | tail -n 1)" || value=""
  fi
  case "$value" in
    on|off) printf '%s\n' "$value" ;;
    *) printf 'on\n' ;;
  esac
}

set_firewall_state() {
  value="$1"
  case "$value" in on|off) ;; *) echo "kris-runtimectl: valore non valido" >&2; exit 2 ;; esac
  tmp="$(mktemp "$STATE_DIR/.runtime.conf.XXXXXX")"
  trap 'rm -f "$tmp"' EXIT
  printf 'FIREWALL=%s\n' "$value" > "$tmp"
  chmod 0644 "$tmp"
  chown root:root "$tmp"
  mv -f "$tmp" "$STATE_FILE"
  trap - EXIT
}

unit_exists() {
  systemctl cat "$1" >/dev/null 2>&1
}

apply_firewall() {
  if ! unit_exists firewalld.service; then
    echo "kris-runtimectl: firewalld non disponibile" >&2
    exit 69
  fi
  if [ "$(firewall_state)" = on ]; then
    systemctl start firewalld.service
  else
    systemctl stop firewalld.service
  fi
}

set_bluetooth() {
  case "$1" in
    on) rfkill unblock bluetooth ;;
    off) rfkill block bluetooth ;;
    *) echo "kris-runtimectl: valore non valido" >&2; exit 2 ;;
  esac
}

bluetooth_state() {
  if ! out="$(rfkill -n -o SOFT list bluetooth 2>/dev/null)"; then
    echo unknown
    return 0
  fi
  line="$(printf '%s\n' "$out" | head -n 1)"
  case "$line" in
    unblocked) echo on ;;
    blocked) echo off ;;
    *) echo absent ;;
  esac
}

status_text() {
  printf 'firewall=%s\n' "$(firewall_state)"
  printf 'bluetooth=%s\n' "$(bluetooth_state)"
}

status_json() {
  printf '{"schema":1,"firewall":"%s","bluetooth":"%s"}\n' \
    "$(firewall_state)" "$(bluetooth_state)"
}

cmd="${1:-}"
case "$cmd" in
  status)
    if [ "${2:-}" = "--json" ]; then
      [ "$#" -eq 2 ] || { usage >&2; exit 2; }
      status_json
    else
      [ "$#" -eq 1 ] || { usage >&2; exit 2; }
      status_text
    fi
    ;;
  is-on)
    [ "$#" -eq 2 ] && [ "$2" = firewall ] || { usage >&2; exit 2; }
    [ "$(firewall_state)" = on ]
    ;;
  firewall)
    need_root
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    ensure_state
    set_firewall_state "$2"
    apply_firewall
    ;;
  bluetooth)
    need_root
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    set_bluetooth "$2"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
