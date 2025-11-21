#!/usr/bin/env bash
set -euo pipefail
WKSP="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
cd "$WKSP"
# ensure DISPLAY available in non-login shells
[ -f /etc/profile.d/graphical_clock_env.sh ] && source /etc/profile.d/graphical_clock_env.sh || true
# configure out-of-source and build visual_clock
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug || { echo 'cmake configure failed' >&2; exit 2; }
cmake --build build --target visual_clock -- -j2 || { echo 'build failed' >&2; exit 3; }
# verify binary
if [ ! -x build/visual_clock ]; then echo 'visual_clock binary not found after build' >&2; exit 4; fi
echo 'build/visual_clock ready'
