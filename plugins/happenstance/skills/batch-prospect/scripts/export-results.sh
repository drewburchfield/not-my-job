#!/usr/bin/env bash
# Export Happenstance search results to CSV, markdown, or JSON
# Reads JSON results array from stdin
#
# Usage:
#   cat results.json | ./export-results.sh --format csv
#   cat results.json | ./export-results.sh --format markdown
#   cat results.json | ./export-results.sh --format json
#
# Input: JSON array of search result objects (from accumulated search pages)
# Each object should have: name, current_title (or title), current_company (or company),
# summary, weighted_traits_score, socials.linkedin_url (or linkedin_url),
# socials.twitter_url (or twitter_url). Fields use fallback chains.

set -euo pipefail

FORMAT="markdown"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      shift
      FORMAT="${1:-markdown}"
      ;;
    --help|-h)
      echo "Usage: cat results.json | $0 --format [csv|markdown|json]"
      echo ""
      echo "Formats:"
      echo "  csv       Comma-separated values with header row"
      echo "  markdown  Markdown table"
      echo "  json      Pretty-printed JSON (passthrough)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: cat results.json | $0 --format [csv|markdown|json]" >&2
      exit 1
      ;;
  esac
  shift
done

# Validate format before consuming stdin
case "$FORMAT" in
  csv|markdown|json) ;;
  *)
    echo "Unknown format: $FORMAT (use csv, markdown, or json)" >&2
    exit 1
    ;;
esac

# Read all stdin
INPUT=$(cat)

if [[ -z "$INPUT" ]]; then
  echo "Error: No input provided. Pipe JSON results array to stdin." >&2
  echo "Usage: cat results.json | $0 --format [csv|markdown|json]" >&2
  exit 1
fi

if ! echo "$INPUT" | jq empty 2>/dev/null; then
  echo "Error: Input is not valid JSON" >&2
  exit 1
fi

if ! echo "$INPUT" | jq -e 'type == "array"' > /dev/null 2>&1; then
  echo "Error: Input must be a JSON array of result objects" >&2
  exit 1
fi

case "$FORMAT" in
  csv)
    echo "Name,Title,Company,Summary,Score,LinkedIn,Twitter"
    echo "$INPUT" | jq -r '
      .[] |
      [
        (.name // ""),
        (.current_title // .title // ""),
        (.current_company // .company // ""),
        ((.summary // "") | gsub("\n"; " ")),
        (.weighted_traits_score // ""),
        (.socials.linkedin_url // .linkedin_url // ""),
        (.socials.twitter_url // .twitter_url // "")
      ] | @csv
    '
    ;;

  markdown)
    echo "| Name | Title | Company | Score | LinkedIn | Twitter |"
    echo "|---|---|---|---|---|---|"
    echo "$INPUT" | jq -r '
      def escape_pipe: gsub("\\|"; "\\|");
      .[] |
      "| " +
      ((.name // "-") | escape_pipe) + " | " +
      ((.current_title // .title // "-") | escape_pipe) + " | " +
      ((.current_company // .company // "-") | escape_pipe) + " | " +
      ((.weighted_traits_score // null) | if . == null then "-" else tostring end) + " | " +
      (if (.socials.linkedin_url // .linkedin_url) then "[link](" + (.socials.linkedin_url // .linkedin_url) + ")" else "-" end) + " | " +
      (if (.socials.twitter_url // .twitter_url) then "[link](" + (.socials.twitter_url // .twitter_url) + ")" else "-" end) + " |"
    '
    ;;

  json)
    echo "$INPUT" | jq '.'
    ;;
esac
