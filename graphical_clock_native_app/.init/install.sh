#!/usr/bin/env bash
set -euo pipefail
# idempotent install of required build and dev headers
WKSP="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
sudo apt-get update -q >/dev/null
PKGS=(cmake pkg-config libx11-dev libgtk-4-dev libglib2.0-dev libpulse-dev binutils x11-utils lsof xdpyinfo pstree)
TOINSTALL=()
for p in "${PKGS[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || TOINSTALL+=("$p"); done
if [ ${#TOINSTALL[@]} -gt 0 ]; then sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${TOINSTALL[@]}" >/dev/null; fi
# ensure clang++ present
if ! command -v clang++ >/dev/null 2>&1; then sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends clang >/dev/null; fi
command -v clang++ >/dev/null || { echo "ERROR: clang++ missing after install" >&2; exit 4; }
# persist DISPLAY and workspace
PROFILE=/etc/profile.d/graphical_clock_env.sh
sudo bash -c "cat > $PROFILE <<'EOF'
# graphical_clock_native_app global env
export DISPLAY=:99
export GRAPHICAL_CLOCK_WORKSPACE=${WKSP}
EOF"
sudo chmod 644 "$PROFILE"
# source into current shell
# shellcheck disable=SC1090
source "$PROFILE"
# validate pkg-config and gtk4
command -v pkg-config >/dev/null || { echo "ERROR: pkg-config missing" >&2; exit 5; }
if ! pkg-config --exists gtk4; then echo "ERROR: gtk4 development pkg not found via pkg-config. Install libgtk-4-dev or set PKG_CONFIG_PATH" >&2; exit 6; fi
# verify g++ and cmake
command -v g++ >/dev/null || { echo 'ERROR: g++ missing' >&2; exit 7; }
command -v cmake >/dev/null || { echo 'ERROR: cmake missing' >&2; exit 8; }
# sanity: print versions (minimal output)
g++ --version | head -n1 || true
clang++ --version | head -n1 || true
cmake --version | head -n1 || true
pkg-config --modversion gtk4 >/dev/null 2>&1 && echo "gtk4 pkg-config found: $(pkg-config --modversion gtk4)" || true
