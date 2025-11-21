#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
export DISPLAY="${DISPLAY:-:99}"
cd "$WS"
if [ ! -x "$WS/start_app.sh" ]; then echo "start_app.sh not found or not executable" >&2; exit 4; fi
# Start without failing if it exits quickly; the validation script will check
"$WS/start_app.sh"
