#!/usr/bin/env bash
set -euo pipefail
# PUBLIC_INTERFACE
# build_image builds the Docker image for the graphical clock app.
# Usage: ./docker-build.sh [tag]
build_image() {
  /** Builds the Docker image using the local Dockerfile. */
  local tag="${1:-visual-clock:dev}"
  docker build -t "$tag" .
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  build_image "${1:-visual-clock:dev}"
fi
