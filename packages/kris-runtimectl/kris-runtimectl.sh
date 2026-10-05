set -euo pipefail

STATE_DIR=/var/lib/krisos
STATE_FILE="$STATE_DIR/runtime.conf"

usage() {
  cat <<'USAGE'
Uso:
  kris-runtimectl status [--json]
  kris-runtimectl is-on firewall
  kris-runtimectl firewall on|off
  kris-runtimectl bluetooth on|off

Solo la policy persistente del firewall viene salvata in
/var/lib/krisos/runtime.conf. Il comando status riporta invece anche
lo stato runtime reale di firewalld.

Lo stato Bluetooth resta nativo rfkill/BlueZ e non viene salvato
da kris-runtimectl.

I comandi di modifica richiedono privilegi amministrativi.
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
    *)      printf 'on\n' ;;
  esac
}

set_firewall_state() {
  value="$1"

  case "$value" in
    on|off) ;;
    *)
      echo "kris-runtimectl: valore firewall non valido" >&2
      exit 2
      ;;
  esac

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

firewall_runtime_state() {
  if ! unit_exists firewalld.service; then
    printf 'unavailable\n'
  elif systemctl is-active --quiet firewalld.service; then
    printf 'on\n'
  else
    printf 'off\n'
  fi
}

apply_firewall() {
  if ! unit_exists firewalld.service; then
    echo "kris-runtimectl: firewalld non disponibile" >&2
    return 69
  fi

  if [ "$(firewall_state)" = on ]; then
    systemctl start firewalld.service
  else
    systemctl stop firewalld.service
  fi
}

set_firewall() {
  requested="$1"
  previous="$(firewall_state)"

  set_firewall_state "$requested"
  apply_firewall || {
    rc=$?
    set_firewall_state "$previous"
    return "$rc"
  }
}

apply_bluetooth() {
  case "$1" in
    on)
      rfkill unblock bluetooth
      timeout 15s bluetoothctl power on
      ;;
    off)
      # Power BlueZ down first when a controller is available, then enforce the
      # radio block. rfkill remains the final fail-safe for the OFF direction.
      timeout 15s bluetoothctl power off >/dev/null 2>&1 || true
      rfkill block bluetooth
      ;;
    *)
      echo "kris-runtimectl: valore bluetooth non valido" >&2
      exit 2
      ;;
  esac
}

status_text() {
  printf 'firewall=%s\n' "$(firewall_runtime_state)"
  printf 'firewall_policy=%s\n' "$(firewall_state)"
}

status_json() {
  printf '{"schema":1,"firewall":"%s","firewallPolicy":"%s"}\n' \
    "$(firewall_runtime_state)" "$(firewall_state)"
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
    [ "$#" -eq 2 ] && [ "$2" = firewall ] || {
      usage >&2
      exit 2
    }

    [ "$(firewall_state)" = on ]
    ;;

  firewall)
    need_root
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }

    ensure_state
    set_firewall "$2"
    ;;

  bluetooth)
    need_root
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }

    apply_bluetooth "$2"
    ;;

  -h|--help|help)
    usage
    ;;

  *)
    usage >&2
    exit 2
    ;;
esac
