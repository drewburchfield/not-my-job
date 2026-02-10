#!/bin/bash
# Usage: ./generate-html.sh <categorized_json> <output_html>
# Populates template.html with newsletter data

set -euo pipefail

INPUT="${1:?Input JSON required}"
OUTPUT="${2:?Output HTML required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/template.html"

echo "Generating HTML digest..." >&2

# Verify inputs
if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: Input file not found: $INPUT" >&2
    exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
    echo "ERROR: Template not found: $TEMPLATE" >&2
    exit 1
fi

DATE=$(date "+%B %d, %Y")
TOTAL_COUNT=$(jq 'length' "$INPUT")

# Simplify newsletters for HTML (keep only essential fields)
NEWSLETTERS_JS=$(jq -c '[.[] | {
    id: .id,
    threadId: .id,
    topic: .topic,
    title: (.subject // "Untitled"),
    source: ((.from // "Unknown") | gsub("\""; "") | gsub("<.*>"; "") | gsub("\\s+$"; "") | gsub("^\\s+"; "")),
    date: ((.date // "") | split(" ")[0:2] | join(" ")),
    isNew: false,
    tldr: "",
    insights: [],
    quote: null,
    links: [],
    overlap: []
}]' "$INPUT")

# Replace placeholders in template
sed -e "s|{{DATE}}|$DATE|g" \
    -e "s|{{TOTAL_COUNT}}|$TOTAL_COUNT|g" \
    "$TEMPLATE" > "$OUTPUT.tmp"

# Inject newsletters array using awk (safer than sed for JSON)
awk -v json="$NEWSLETTERS_JS" '
    /const NL = \[\];/ {
        print "const NL = " json ";"
        next
    }
    { print }
' "$OUTPUT.tmp" > "$OUTPUT"
rm "$OUTPUT.tmp"

echo "✓ Generated: $OUTPUT ($TOTAL_COUNT newsletters)" >&2
echo "" >&2
echo "Next steps:" >&2
echo "  1. Open $OUTPUT in your browser" >&2
echo "  2. Review newsletters one-at-a-time (S=save, A=archive, Space=skip)" >&2
echo "  3. Click 'Save Decisions to File' when done" >&2
echo "  4. Decisions file will download to ~/Downloads/" >&2

exit 0
