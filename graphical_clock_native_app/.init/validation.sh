#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
cd "$WS"
# Ensure configure present
if [ ! -f build/CMakeCache.txt ]; then cmake -S . -B build > build/configure.log 2>&1 || { echo "cmake configure failed, tail build/configure.log" >&2; tail -n 200 build/configure.log >&2; exit 2; }; fi
# Build clock_app
cmake --build build --target clock_app -- -j2
# Start app
export DISPLAY="${DISPLAY:-:99}"
if [ ! -x "$WS/start_app.sh" ]; then echo "start_app.sh not found or not executable" >&2; exit 4; fi
"$WS/start_app.sh"
# Wait/poll up to 5s for pid file and process to be alive
PID=""
for i in {1..10}; do
  if [ -f "$WS/clock_app.pid" ]; then PID=$(cat "$WS/clock_app.pid" 2>/dev/null || true); fi
  if [ -n "${PID-}" ] && kill -0 "$PID" 2>/dev/null; then break; fi
  sleep 0.5
done
if [ -z "${PID-}" ] || ! kill -0 "$PID" 2>/dev/null; then echo "ERROR: app failed to start" >&2; tail -n 200 "$WS/clock_app.log" || true; exit 3; fi
# Evidence
ps -p "$PID" -o pid,cmd || true
echo "--- clock_app log tail ---"; tail -n 50 "$WS/clock_app.log" || true
# Stop app (attempt graceful, then force if needed)
if [ -x "$WS/stop_app.sh" ]; then
  "$WS/stop_app.sh" || true
fi
# If pid file still present, warn and attempt forced kill
if [ -f "$WS/clock_app.pid" ]; then
  PID2=$(cat "$WS/clock_app.pid" 2>/dev/null || true)
  if [ -n "$PID2" ] && kill -0 "$PID2" 2>/dev/null; then
    echo "WARN: pid file still present, forcing kill of $PID2" >&2
    kill -9 "$PID2" 2>/dev/null || true
  fi
  rm -f "$WS/clock_app.pid" || true
fi
echo "Validation succeeded"
