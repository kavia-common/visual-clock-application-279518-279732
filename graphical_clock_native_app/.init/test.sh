#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
cd "$WS"
# run any tests if built
if [ -f build/Testing/Temporary/LastTest.txt ] || [ -d build ]; then
  cmake --build build --target test -- -j2 || true
  # attempt to run ctest if available
  if command -v ctest >/dev/null 2>&1; then
    (cd build && ctest --output-on-failure -j2) || true
  fi
fi
