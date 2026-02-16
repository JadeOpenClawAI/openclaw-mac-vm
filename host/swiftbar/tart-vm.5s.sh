#!/usr/bin/env bash
set -euo pipefail

CTL="${HOME}/Scripts/tart-vm-control.sh"
STATUS="$(${CTL} status 2>/dev/null || echo 'unknown')"
MODE="$(${CTL} mode 2>/dev/null || echo 'headless')"

if [[ "${STATUS}" == running* ]]; then
  if [[ "${MODE}" == headless ]]; then
    echo "Tart VM: ${STATUS} | sfimage=desktopcomputer"
  else
    echo "Tart VM: ${STATUS} | sfimage=macwindow"
  fi
else
  echo "Tart VM: ${STATUS} | sfimage=exclamationmark.octagon"
fi

echo "---"
echo "Start | bash='${CTL}' param1=start terminal=false refresh=true"
echo "Stop | bash='${CTL}' param1=stop terminal=false refresh=true"
echo "Restart | bash='${CTL}' param1=restart terminal=false refresh=true"
echo "---"
if [[ "${MODE}" == "headless" ]]; then
  echo "Switch to Graphics (restart) | bash='${CTL}' param1=toggle-mode-restart terminal=false refresh=true"
else
  echo "Switch to Headless (restart) | bash='${CTL}' param1=toggle-mode-restart terminal=false refresh=true"
fi
echo "---"
echo "Open Tart log | bash='open' param1='${HOME}/Library/Application Support/TartVM/tart.log' terminal=false"
echo "Open launchd stdout | bash='open' param1='${HOME}/Library/Logs/tart-vm.launchd.out.log' terminal=false"
echo "Open launchd stderr | bash='open' param1='${HOME}/Library/Logs/tart-vm.launchd.err.log' terminal=false"
