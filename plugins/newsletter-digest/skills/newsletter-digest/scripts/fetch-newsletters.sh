#!/bin/bash
# Usage: ./fetch-newsletters.sh <timeframe> <output_file>
# Example: ./fetch-newsletters.sh 7d newsletters-raw.json

set -euo pipefail

TIMEFRAME="${1:-7d}"
OUTPUT="${2:-newsletters-raw.json}"

# Query patterns - customize based on your inbox structure
QUERY="in:inbox (from:substack.com OR from:lennysnewsletter.com OR from:beehiiv.com OR from:producttapas OR from:natesnewsletter OR label:[Superhuman]/AI/AI_Newsletters_and_Content) newer_than:$TIMEFRAME"

echo "Fetching newsletters from last $TIMEFRAME..." >&2

# Fetch newsletters using gog CLI
if ! gog gmail search "$QUERY" --max 50 --json --no-input > "$OUTPUT" 2>&1; then
    echo "ERROR: Failed to fetch newsletters" >&2
    exit 1
fi

# Validate output
if [[ ! -s "$OUTPUT" ]]; then
    echo "ERROR: No newsletters fetched (empty output)" >&2
    exit 1
fi

# Verify JSON structure
if ! jq -e '.threads' "$OUTPUT" > /dev/null 2>&1; then
    echo "ERROR: Invalid JSON response from gog CLI" >&2
    cat "$OUTPUT" >&2
    exit 1
fi

COUNT=$(jq '.threads | length' "$OUTPUT")
echo "✓ Fetched $COUNT newsletters" >&2

# Exit with success
exit 0
