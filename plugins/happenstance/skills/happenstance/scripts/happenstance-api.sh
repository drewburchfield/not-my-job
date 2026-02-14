#!/usr/bin/env bash
# Happenstance API helper script
# Usage:
#   ./happenstance-api.sh research "Garry Tan CEO Y Combinator @garrytan"
#   ./happenstance-api.sh search "Software engineers in San Francisco" [--friends] [--connections] [--groups '["id"]']
#   ./happenstance-api.sh poll-research <research_id>
#   ./happenstance-api.sh poll-search <search_id>
#   ./happenstance-api.sh find-more <search_id>
#   ./happenstance-api.sh groups
#   ./happenstance-api.sh usage

set -euo pipefail

BASE_URL="https://api.happenstance.ai/v1"

if [[ -z "${HAPPENSTANCE_API_KEY:-}" ]]; then
  echo "Error: HAPPENSTANCE_API_KEY not set" >&2
  echo "Get your key at https://happenstance.ai/settings/api" >&2
  exit 1
fi

AUTH_HEADER="Authorization: Bearer ${HAPPENSTANCE_API_KEY}"
CONTENT_TYPE="Content-Type: application/json"

api_get() {
  local url="$1"
  local response
  response=$(curl -sS --fail-with-body --max-time 30 -X GET "$url" -H "$AUTH_HEADER") || {
    echo "Error: GET $url failed" >&2
    echo "$response" >&2
    return 1
  }
  echo "$response"
}

api_post() {
  local url="$1"
  local data="${2:-}"
  local curl_args=(-sS --fail-with-body --max-time 30 -X POST "$url" -H "$AUTH_HEADER")
  if [[ -n "$data" ]]; then
    curl_args+=(-H "$CONTENT_TYPE" -d "$data")
  fi
  local response
  response=$(curl "${curl_args[@]}") || {
    echo "Error: POST $url failed" >&2
    echo "$response" >&2
    return 1
  }
  echo "$response"
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  research)
    description="${1:?Error: research requires a description argument}"
    api_post "$BASE_URL/research" "{\"description\": $(printf '%s' "$description" | jq -Rs .)}"
    ;;

  poll-research)
    research_id="${1:?Error: poll-research requires a research_id argument}"
    api_get "$BASE_URL/research/$research_id"
    ;;

  search)
    text="${1:?Error: search requires a text argument}"
    shift || true
    include_friends="false"
    include_connections="false"
    group_ids=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --friends) include_friends="true" ;;
        --connections) include_connections="true" ;;
        --groups)
          shift
          group_ids="${1:?Error: --groups requires a JSON array argument}"
          if ! printf '%s' "$group_ids" | jq -e 'type == "array"' > /dev/null 2>&1; then
            echo "Error: --groups argument must be a valid JSON array" >&2
            exit 1
          fi
          ;;
        *) echo "Unknown flag: $1" >&2; exit 1 ;;
      esac
      shift
    done

    body="{\"text\": $(printf '%s' "$text" | jq -Rs .), \"include_friends_connections\": $include_friends, \"include_my_connections\": $include_connections"
    if [[ -n "$group_ids" ]]; then
      body="$body, \"group_ids\": $group_ids"
    fi
    body="$body}"
    api_post "$BASE_URL/search" "$body"
    ;;

  poll-search)
    search_id="${1:?Error: poll-search requires a search_id argument}"
    page_id="${2:-}"
    if [[ -n "$page_id" ]]; then
      api_get "$BASE_URL/search/$search_id?page_id=$page_id"
    else
      api_get "$BASE_URL/search/$search_id"
    fi
    ;;

  find-more)
    search_id="${1:?Error: find-more requires a search_id argument}"
    api_post "$BASE_URL/search/$search_id/find-more"
    ;;

  groups)
    api_get "$BASE_URL/groups"
    ;;

  usage)
    api_get "$BASE_URL/usage"
    ;;

  help)
    echo "Happenstance API CLI"
    echo ""
    echo "Commands:"
    echo "  research <description>     Start a person research (1 credit)"
    echo "  poll-research <id>         Check research status/results"
    echo "  search <text> [flags]      Start a network search (2 credits)"
    echo "    --friends                Include friends' connections"
    echo "    --connections            Include your connections"
    echo "    --groups <json_array>    Specify group IDs"
    echo "  poll-search <id> [page]    Check search status/results"
    echo "  find-more <id>             Get more search results (2 credits)"
    echo "  groups                     List your groups"
    echo "  usage                      Check credit balance"
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    echo "Run '$0 help' for usage" >&2
    exit 1
    ;;
esac
