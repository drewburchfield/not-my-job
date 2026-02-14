#!/usr/bin/env bash
# SessionStart hook: Check for HAPPENSTANCE_API_KEY and report missing dependencies
set -euo pipefail

cat > /dev/null  # Consume stdin

missing=()

if [[ -z "${HAPPENSTANCE_API_KEY:-}" ]]; then
  missing+=("HAPPENSTANCE_API_KEY not set (get key at https://happenstance.ai/settings/api)")
fi

if ! command -v curl &>/dev/null; then
  missing+=("curl not found (required for API requests)")
fi

if ! command -v jq &>/dev/null; then
  missing+=("jq not found (install: brew install jq)")
fi

if ! command -v bc &>/dev/null; then
  missing+=("bc not found (required for credit checks)")
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "happenstance: Missing dependencies:"
  for msg in "${missing[@]}"; do
    echo "  - $msg"
  done
  # Hooks must exit 0 to avoid blocking the session; warnings only
  exit 0
fi

echo "happenstance: Ready (API key + curl + jq + bc configured)"
exit 0
