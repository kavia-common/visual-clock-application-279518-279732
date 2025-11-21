#!/usr/bin/env bash
set -euo pipefail
# Dependencies - vendor Catch2 single-header with checksum and configure build
WS="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
cd "$WS"
mkdir -p vendor build
CATCH_URL="https://github.com/catchorg/Catch2/releases/download/v2.13.10/catch.hpp"
TARGET="vendor/catch.hpp"
# NOTE: The authoritative SHA256 must be provided by the architect. The placeholder below will cause a mismatch if it is not the correct checksum.
EXPECTED_SHA256="3c9b4e2f6a6f7e6d5a8a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2"
if [ ! -f "$TARGET" ]; then
  curl -sSL --retry 3 --connect-timeout 10 "$CATCH_URL" -o "$TARGET" || { echo "ERROR: failed to download Catch2 header" >&2; exit 2; }
fi
# Verify integrity if possible
if command -v sha256sum >/dev/null 2>&1; then
  actual_sha=$(sha256sum "$TARGET" | awk '{print $1}')
  if [ "${EXPECTED_SHA256:-}" != "" ] && [ "$actual_sha" != "$EXPECTED_SHA256" ]; then
    echo "ERROR: catch.hpp SHA256 mismatch (actual: $actual_sha)" >&2
    ls -l "$TARGET" >&2
    exit 3
  fi
else
  # Fallback sanity check: file present and reasonable size
  sz=$(stat -c%s "$TARGET" 2>/dev/null || true)
  if [ -z "$sz" ] || [ "$sz" -lt 1000 ]; then
    echo "ERROR: catch.hpp size suspicious ($sz)" >&2
    exit 4
  fi
fi
# Run cmake configure and capture output to build/configure.log
cmake -S . -B build > build/configure.log 2>&1 || { echo "cmake configure failed, tail build/configure.log:" >&2; tail -n 200 build/configure.log >&2; exit 5; }
# Success
echo "OK: vendored catch.hpp present and cmake configure completed. Log: build/configure.log"
