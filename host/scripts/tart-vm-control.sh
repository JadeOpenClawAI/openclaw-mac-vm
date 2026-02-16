#!/usr/bin/env bash
set -euo pipefail

LABEL="${LABEL:-com.user.tart-vm}"
VM_NAME="${VM_NAME:-tahoe-base}"
BRIDGE_IF="${BRIDGE_IF:-en0}"
PLIST="${PLIST:-${HOME}/Library/LaunchAgents/${LABEL}.plist}"
STATE_DIR="${STATE_DIR:-${HOME}/Library/Application Support/TartVM}"
MODE_FILE="${MODE_FILE:-${STATE_DIR}/mode}" # headless|graphics
PID_FILE="${PID_FILE:-${STATE_DIR}/pid}"
LOG_FILE="${LOG_FILE:-${STATE_DIR}/tart.log}"

mkdir -p "${STATE_DIR}"

get_mode() {
  if [[ -f "${MODE_FILE}" ]]; then cat "${MODE_FILE}"; else echo "headless"; fi
}

set_mode() {
  local mode="$1"
  [[ "$mode" == "headless" || "$mode" == "graphics" ]] || { echo "Invalid mode: $mode" >&2; exit 1; }
  echo "$mode" > "${MODE_FILE}"
}

is_running() {
  if launchctl print "gui/${UID}/${LABEL}" >/dev/null 2>&1; then
    launchctl print "gui/${UID}/${LABEL}" 2>/dev/null | grep -qE '^\s*pid = [1-9]' && return 0
  fi
  if [[ -f "${PID_FILE}" ]]; then
    local pid
    pid="$(cat "${PID_FILE}" || true)"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && return 0
  fi
  return 1
}

run_vm_forever() {
  local mode no_graphics_arg
  while true; do
    mode="$(get_mode)"
    no_graphics_arg=""
    [[ "$mode" == "headless" ]] && no_graphics_arg="--no-graphics"

    echo "[$(date -Iseconds)] Starting Tart VM ${VM_NAME} mode=${mode} ${no_graphics_arg}" | tee -a "${LOG_FILE}"
    tart run "${VM_NAME}" --net-bridged="${BRIDGE_IF}" ${no_graphics_arg} >>"${LOG_FILE}" 2>&1 &
    echo $! > "${PID_FILE}"

    wait "$(cat "${PID_FILE}")" || true
    rm -f "${PID_FILE}"

    echo "[$(date -Iseconds)] Tart exited. Restarting in 2s…" | tee -a "${LOG_FILE}"
    sleep 2
  done
}

start_agent() {
  launchctl bootstrap "gui/${UID}" "${PLIST}" 2>/dev/null || true
  launchctl enable "gui/${UID}/${LABEL}" 2>/dev/null || true
  launchctl kickstart -k "gui/${UID}/${LABEL}" 2>/dev/null || true
}

stop_agent() {
  launchctl disable "gui/${UID}/${LABEL}" 2>/dev/null || true
  launchctl bootout "gui/${UID}" "${PLIST}" 2>/dev/null || true

  if [[ -f "${PID_FILE}" ]]; then
    pid="$(cat "${PID_FILE}" || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
      sleep 0.5
      kill -KILL "$pid" 2>/dev/null || true
    fi
    rm -f "${PID_FILE}"
  fi
}

restart_agent() {
  stop_agent
  sleep 1
  start_agent
}

print_status() {
  local mode status
  mode="$(get_mode)"
  status="stopped"
  is_running && status="running"
  echo "${status} (${mode})"
}

usage() {
  cat <<EOF
Usage: $0 <command>
Commands:
  run
  start
  stop
  restart
  mode
  set-headless
  set-graphics
  toggle-mode
  toggle-mode-restart
  status

Environment overrides:
  LABEL, VM_NAME, BRIDGE_IF, PLIST, STATE_DIR
EOF
}

cmd="${1:-}"
case "$cmd" in
  run) run_vm_forever ;;
  start) start_agent ;;
  stop) stop_agent ;;
  restart) restart_agent ;;
  mode) get_mode ;;
  set-headless) set_mode "headless" ;;
  set-graphics) set_mode "graphics" ;;
  toggle-mode)
    if [[ "$(get_mode)" == "headless" ]]; then
      set_mode "graphics"
    else
      set_mode "headless"
    fi
    ;;
  toggle-mode-restart)
    if [[ "$(get_mode)" == "headless" ]]; then
      set_mode "graphics"
    else
      set_mode "headless"
    fi
    restart_agent
    ;;
  status) print_status ;;
  ""|-h|--help) usage ;;
  *) echo "Unknown command: ${cmd}" >&2; usage; exit 1 ;;
esac
