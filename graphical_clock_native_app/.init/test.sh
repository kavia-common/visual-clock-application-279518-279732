#!/usr/bin/env bash
set -euo pipefail
WKSP="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
cd "$WKSP"
# load persisted env if present
[ -f /etc/profile.d/graphical_clock_env.sh ] && source /etc/profile.d/graphical_clock_env.sh || true
# Configure cmake out-of-source
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug || { echo 'cmake configure failed' >&2; exit 2; }
# Build test target if present; allow failure without abort so ctest can still run discovered tests
cmake --build build --target test_dummy -- -j2 || true
# Run tests via ctest to avoid hardcoded paths; fail fast on failure and show output
if command -v ctest >/dev/null 2>&1; then
  ctest --test-dir build --output-on-failure || { echo 'unit tests failed' >&2; exit 3; }
else
  # fallback: attempt to locate any test executable matching test_dummy* inside build
  TEST_BIN=$(find build -type f -executable -name "test_dummy*" | head -n1 || true)
  if [ -n "$TEST_BIN" ]; then
    "$TEST_BIN" || { echo 'unit tests failed (fallback runner)' >&2; exit 4; }
  else
    echo 'No ctest installed and no test binary found' >&2
    exit 5
  fi
fi
