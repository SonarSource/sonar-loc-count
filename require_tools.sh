#!/bin/bash
# require_tools <tool>... : exit with install hints if any tool is missing from PATH.
# Sourced so scripts fail early, before any API calls or clones.
require_tools() {
  local tool missing=0
  for tool in "$@"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "Error: '$tool' is required but not installed or not on PATH." >&2
      case "$tool" in
        gsed) echo "  Install it with: brew install gnu-sed" >&2 ;;
        *)    echo "  Install it with: brew install $tool (macOS) or your package manager" >&2 ;;
      esac
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || exit 1
}
