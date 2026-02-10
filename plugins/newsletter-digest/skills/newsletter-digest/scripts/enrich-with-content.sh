#!/bin/bash
# Usage: ./enrich-with-content.sh <input_json> <output_json>
# Fetches full thread content for each newsletter and adds preview text

set -euo pipefail

INPUT="${1:?Input JSON required}"
OUTPUT="${2:?Output JSON required}"

echo "Enriching newsletters with content previews..." >&2

# Verify input exists
if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: Input file not found: $INPUT" >&2
    exit 1
fi

COUNT=$(jq '.threads | length' "$INPUT")
echo "Fetching content for $COUNT newsletters..." >&2

# Process each thread
jq -r '.threads[] | @json' "$INPUT" | while read -r newsletter; do
    threadId=$(echo "$newsletter" | jq -r '.id')

    # Fetch full thread content
    THREAD_CONTENT=$(gog gmail thread get "$threadId" --full --no-input 2>/dev/null | head -100)

    # Extract first paragraph of content (skip headers)
    PREVIEW=$(echo "$THREAD_CONTENT" | awk '
        /^$/ { blank++; next }
        blank >= 2 && NF > 0 {
            print
            count++
            if (count >= 5) exit
        }
    ' | tr '\n' ' ' | sed 's/  */ /g' | cut -c 1-250)

    # Add preview to newsletter object
    echo "$newsletter" | jq --arg preview "$PREVIEW..." '. + {preview: $preview}'
done | jq -s '{threads: .}' > "$OUTPUT"

echo "✓ Enriched $COUNT newsletters with content previews" >&2
exit 0
