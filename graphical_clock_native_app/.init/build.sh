#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
cd "$WS"
# configure if needed and capture logs
mkdir -p build
if [ ! -f build/CMakeCache.txt ]; then cmake -S . -B build > build/configure.log 2>&1 || { echo "cmake configure failed, tail build/configure.log" >&2; tail -n 200 build/configure.log >&2; exit 2; }; fi
# build clock_app target
cmake --build build --target clock_app -- -j2
