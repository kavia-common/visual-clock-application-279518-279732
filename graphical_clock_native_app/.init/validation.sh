#!/usr/bin/env bash
set -euo pipefail
WKSP="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
cd "$WKSP"
# ensure persisted env variables available
[ -f /etc/profile.d/graphical_clock_env.sh ] && source /etc/profile.d/graphical_clock_env.sh || true
: "DISPLAY=${DISPLAY:-}" >/dev/null
if [ -z "${DISPLAY:-}" ]; then echo 'DISPLAY not set; cannot start GUI' >&2; exit 10; fi
# check X server responsiveness
if ! command -v xdpyinfo >/dev/null 2>&1; then echo 'xdpyinfo not installed' >&2; exit 21; fi
if ! xdpyinfo >/dev/null 2>&1; then echo "X server not responsive on DISPLAY=$DISPLAY" >&2; exit 11; fi
# Ensure basic build tools available
command -v cmake >/dev/null 2>&1 || { echo 'cmake not found' >&2; exit 22; }
command -v g++ >/dev/null 2>&1 || command -v clang++ >/dev/null 2>&1 || { echo 'C++ compiler not found' >&2; exit 23; }
# Configure and build all targets
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug || { echo 'cmake configure failed' >&2; exit 12; }
cmake --build build -- -j2 || { echo 'build failed' >&2; exit 13; }
# Start app via start.sh (start.sh expected to write PID file at workspace root)
if [ ! -x "${WKSP}/start.sh" ]; then chmod +x "${WKSP}/start.sh" || true; fi
PID_OUT=$(bash start.sh) || { echo 'start failed' >&2; exit 14; }
# allow process to settle
sleep 2
PID_FILE="$WKSP/.visual_clock.pid"
if [ ! -f "$PID_FILE" ]; then echo 'PID file not found' >&2; exit 15; fi
PID=$(cat "$PID_FILE")
if ! ps -p "$PID" >/dev/null 2>&1; then echo "process $PID not running" >&2; exit 16; fi
# Capture evidence
ps -o pid,ppid,cmd -p "$PID" > "$WKSP/validation_evidence.txt" || true
command -v pstree >/dev/null 2>&1 && pstree -sp "$PID" >> "$WKSP/validation_evidence.txt" 2>/dev/null || true
command -v lsof >/dev/null 2>&1 && lsof -p "$PID" | grep "/tmp/.X11-unix" > "$WKSP/validation_xsocket.txt" 2>/dev/null || true
xdpyinfo > "$WKSP/validation_xdpyinfo.txt" 2>/dev/null || true
# Stop application cleanly
kill "$PID" && sleep 1 || true
if ps -p "$PID" >/dev/null 2>&1; then kill -9 "$PID" || true; fi
rm -f "$PID_FILE"
# Final status
echo "validation: OK" > "$WKSP/validation_status.txt"
