#!/usr/bin/env bash
set -euo pipefail

# Installs launchd + SwiftBar integration from this repo using templated defaults.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_DIR="$ROOT_DIR/host"

SCRIPT_DEST="${SCRIPT_DEST:-$HOME/Scripts/tart-vm-control.sh}"
PLIST_LABEL="${PLIST_LABEL:-com.user.tart-vm}"
VM_NAME="${VM_NAME:-tahoe-base}"
BRIDGE_IF="${BRIDGE_IF:-en0}"
SWIFTBAR_ENABLE="${SWIFTBAR_ENABLE:-true}"

LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCHAGENTS_DIR/${PLIST_LABEL}.plist"
SWIFTBAR_DIR="${SWIFTBAR_DIR:-$HOME/SwiftBar}"
SWIFTBAR_DEST="$SWIFTBAR_DIR/tart-vm.5s.sh"

mkdir -p "$(dirname "$SCRIPT_DEST")" "$LAUNCHAGENTS_DIR"

cp "$HOST_DIR/scripts/tart-vm-control.sh" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"

# Render plist template safely
sed \
  -e "s|com.user.tart-vm|${PLIST_LABEL}|g" \
  -e "s|/Users/USERNAME/Scripts/tart-vm-control.sh|${SCRIPT_DEST//|/\\|}|g" \
  -e "s|/Users/USERNAME|$HOME|g" \
  "$HOST_DIR/launchagents/com.user.tart-vm.plist" > "$PLIST_DEST"

# Ensure script defaults align with installer options (without hardcoding paths)
# Shellcheck disable for macOS sed portability
sed -i.bak \
  -e "s/^VM_NAME=.*/VM_NAME=\"\${VM_NAME:-${VM_NAME}}\"/" \
  -e "s/^BRIDGE_IF=.*/BRIDGE_IF=\"\${BRIDGE_IF:-${BRIDGE_IF}}\"/" \
  -e "s/^LABEL=.*/LABEL=\"\${LABEL:-${PLIST_LABEL}}\"/" \
  "$SCRIPT_DEST" && rm -f "$SCRIPT_DEST.bak"

launchctl bootout "gui/${UID}" "$PLIST_DEST" 2>/dev/null || true
launchctl bootstrap "gui/${UID}" "$PLIST_DEST"
launchctl enable "gui/${UID}/${PLIST_LABEL}" 2>/dev/null || true
launchctl kickstart -k "gui/${UID}/${PLIST_LABEL}" 2>/dev/null || true

if [[ "$SWIFTBAR_ENABLE" == "true" ]]; then
  mkdir -p "$SWIFTBAR_DIR"
  cp "$HOST_DIR/swiftbar/tart-vm.5s.sh" "$SWIFTBAR_DEST"
  chmod +x "$SWIFTBAR_DEST"
fi

cat <<EOF
Installed host integration.
- Control script: $SCRIPT_DEST
- LaunchAgent: $PLIST_DEST
- Label: $PLIST_LABEL
- VM name: $VM_NAME
- Bridge interface: $BRIDGE_IF
EOF

if [[ "$SWIFTBAR_ENABLE" == "true" ]]; then
  echo "- SwiftBar plugin: $SWIFTBAR_DEST"
fi
