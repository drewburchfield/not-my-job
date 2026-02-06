#!/usr/bin/env bash
#
# Stop hook: Quality gate check
# Reads .claude/project-meta.json for quality gate commands,
# runs them against changed files, and blocks if errors are found.
#

set -euo pipefail

# Read hook input from stdin (consume it - we don't need it for this hook)
HOOK_INPUT=$(cat)

# Find project-meta.json in the current working directory
META_FILE=".claude/project-meta.json"

if [[ ! -f "$META_FILE" ]]; then
  # No meta file = not bootstrapped, pass through silently
  exit 0
fi

# Check if there are any changed files
CHANGED_FILES=$(git diff --name-only 2>/dev/null || true)
STAGED_FILES=$(git diff --staged --name-only 2>/dev/null || true)

if [[ -z "$CHANGED_FILES" ]] && [[ -z "$STAGED_FILES" ]]; then
  # No changes, pass through
  exit 0
fi

# Parse quality gate commands from project-meta.json using python3
# (available on macOS by default, zero additional dependencies)
read_gate() {
  local gate_name="$1"
  python3 -c "
import json
try:
    with open('$META_FILE') as f:
        meta = json.load(f)
    cmd = meta.get('qualityGates', {}).get('$gate_name', '')
    print(cmd)
except Exception:
    print('')
" 2>/dev/null || echo ""
}

TYPE_CHECK_CMD=$(read_gate "typeCheck")
LINT_CMD=$(read_gate "lint")
FORMAT_CMD=$(read_gate "format")

# If no gates configured, pass through
if [[ -z "$TYPE_CHECK_CMD" ]] && [[ -z "$LINT_CMD" ]] && [[ -z "$FORMAT_CMD" ]]; then
  exit 0
fi

ERRORS=""

# Run each quality gate, collecting failures
# TRUST BOUNDARY: Commands come from .claude/project-meta.json, written by the
# bootstrap skill. Treat that file as trusted. Do not run this hook against
# untrusted project-meta.json content.
run_gate() {
  local name="$1"
  local cmd="$2"

  if [[ -z "$cmd" ]]; then
    return
  fi

  local output
  if ! output=$(eval "$cmd" 2>&1); then
    ERRORS="${ERRORS}${name} failed:\n${output}\n\n"
  fi
}

run_gate "Type Check" "$TYPE_CHECK_CMD"
run_gate "Lint" "$LINT_CMD"
run_gate "Format" "$FORMAT_CMD"

if [[ -n "$ERRORS" ]]; then
  # Quality gate failed - block and report errors
  REASON=$(printf "Quality gate errors found. Please fix these issues before completing.\n\n%b" "$ERRORS")

  # Output JSON to block the stop (python3 for safe JSON encoding, no jq dependency)
  python3 -c "
import json, sys
reason = sys.stdin.read()
print(json.dumps({'decision': 'block', 'reason': reason}))
" <<< "$REASON"
  exit 0
fi

# All gates passed - allow stop
exit 0
