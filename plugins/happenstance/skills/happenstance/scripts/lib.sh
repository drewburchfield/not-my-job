#!/usr/bin/env bash
# Shared helpers for Happenstance workflow scripts
# Source this file: source "$(dirname "$0")/lib.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SCRIPT="${SCRIPT_DIR}/happenstance-api.sh"

# Check that the API script exists
if [[ ! -x "$API_SCRIPT" ]]; then
  echo "Error: happenstance-api.sh not found or not executable at $API_SCRIPT" >&2
  exit 1
fi

# ─── Credit Check ─────────────────────────────────────────────

# Check if user has enough credits for an operation
# Usage: check_credits <required_credits>
# Returns: 0 if sufficient (prints balance to stdout), 1 if insufficient or API error (prints message to stderr)
check_credits() {
  local required="${1:?Usage: check_credits <required_credits>}"
  local usage_json
  if ! usage_json=$("$API_SCRIPT" usage 2>&1); then
    echo "Error: Failed to fetch credit balance from API" >&2
    echo "$usage_json" >&2
    return 1
  fi

  # Validate we got a proper response with balance_credits field
  if ! echo "$usage_json" | jq -e '.balance_credits' > /dev/null 2>&1; then
    echo "Error: Could not retrieve credit balance from API" >&2
    echo "Response: $(echo "$usage_json" | head -c 200)" >&2
    return 1
  fi

  local balance has_credits
  balance=$(echo "$usage_json" | jq -r '.balance_credits')
  has_credits=$(echo "$usage_json" | jq -r '.has_credits')

  if [[ "$has_credits" == "false" ]] || (( $(echo "$balance < $required" | bc -l) )); then
    echo "Insufficient credits: have $balance, need $required" >&2
    echo "Purchase credits at https://happenstance.ai/settings/api" >&2
    return 1
  fi

  echo "$balance"
  return 0
}

# ─── Polling ──────────────────────────────────────────────────

# Max polls before timeout. Total wait = MAX_POLLS * interval (default 7s = 420s)
MAX_POLLS=60

# Poll a research request until completion
# Usage: poll_research <research_id> [interval_seconds]
# Outputs: Final JSON result on stdout
poll_research() {
  local research_id="${1:?Usage: poll_research <research_id> [interval]}"
  local interval="${2:-7}"
  local result status poll_count=0

  while true; do
    poll_count=$((poll_count + 1))
    if [[ $poll_count -gt $MAX_POLLS ]]; then
      echo "Error: Polling timed out after $((MAX_POLLS * interval))s for research $research_id" >&2
      echo "The operation may still be running. Check with: poll-research $research_id" >&2
      return 1
    fi

    if ! result=$("$API_SCRIPT" poll-research "$research_id" 2>&1); then
      echo "Warning: Poll attempt $poll_count/$MAX_POLLS failed, retrying in ${interval}s..." >&2
      sleep "$interval"
      continue
    fi

    if ! status=$(echo "$result" | jq -e -r '.status' 2>/dev/null); then
      echo "Error: Malformed response while polling research $research_id" >&2
      echo "Response: $(echo "$result" | head -c 200)" >&2
      return 1
    fi

    case "$status" in
      RUNNING)
        echo "Research $research_id: still running... (poll $poll_count)" >&2
        sleep "$interval"
        ;;
      COMPLETED)
        echo "$result"
        return 0
        ;;
      FAILED|FAILED_AMBIGUOUS)
        echo "Research $research_id: completed with status '$status'" >&2
        echo "$result"
        return 2
        ;;
      *)
        echo "Research $research_id: unexpected status '$status'" >&2
        echo "$result"
        return 1
        ;;
    esac
  done
}

# Poll a search request until completion
# Usage: poll_search <search_id> [page_id] [interval_seconds]
# Outputs: Final JSON result on stdout
poll_search() {
  local search_id="${1:?Usage: poll_search <search_id> [page_id] [interval]}"
  local page_id="${2:-}"
  local interval="${3:-7}"
  local result status poll_count=0
  local poll_args=("$search_id")
  [[ -n "$page_id" ]] && poll_args+=("$page_id")

  while true; do
    poll_count=$((poll_count + 1))
    if [[ $poll_count -gt $MAX_POLLS ]]; then
      echo "Error: Polling timed out after $((MAX_POLLS * interval))s for search $search_id" >&2
      echo "The operation may still be running. Check with: poll-search $search_id" >&2
      return 1
    fi
    if ! result=$("$API_SCRIPT" poll-search "${poll_args[@]}" 2>&1); then
      echo "Warning: Poll attempt $poll_count/$MAX_POLLS failed, retrying in ${interval}s..." >&2
      sleep "$interval"
      continue
    fi

    if ! status=$(echo "$result" | jq -e -r '.status' 2>/dev/null); then
      echo "Error: Malformed response while polling search $search_id" >&2
      echo "Response: $(echo "$result" | head -c 200)" >&2
      return 1
    fi

    case "$status" in
      RUNNING)
        echo "Search $search_id: still running... (poll $poll_count)" >&2
        sleep "$interval"
        ;;
      COMPLETED)
        echo "$result"
        return 0
        ;;
      FAILED)
        echo "Search $search_id: completed with status FAILED" >&2
        echo "$result"
        return 2
        ;;
      *)
        echo "Search $search_id: unexpected status '$status'" >&2
        echo "$result"
        return 1
        ;;
    esac
  done
}

# ─── Formatting ───────────────────────────────────────────────

# Format a credit cost estimate for display
# Usage: format_cost <credits> <description>
format_cost() {
  local credits="${1:?}"
  local desc="${2:?}"
  echo "${credits} credit$([ "$credits" != "1" ] && echo "s") - ${desc}"
}
