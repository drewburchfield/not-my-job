#!/bin/bash
# Usage: ./categorize-newsletters.sh <input_json> <output_json>
# Applies pattern matching rules from references/category-patterns.md

set -euo pipefail

INPUT="${1:?Input JSON required}"
OUTPUT="${2:?Output JSON required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS="$SCRIPT_DIR/../references/category-patterns.md"

echo "Categorizing newsletters..." >&2

# Verify input exists
if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: Input file not found: $INPUT" >&2
    exit 1
fi

# Extract threads and categorize each one
jq -r '.threads[] | @json' "$INPUT" | while read -r newsletter; do
    threadId=$(echo "$newsletter" | jq -r '.id')
    from=$(echo "$newsletter" | jq -r '.messages[0].from // .from // ""' | tr '[:upper:]' '[:lower:]')
    subject=$(echo "$newsletter" | jq -r '.messages[0].subject // .subject // ""')

    category="Uncategorized"

    # AI Tools & Workflows
    if echo "$from" | grep -qi "lenny.*how-i-ai"; then
        category="AI Tools & Workflows"
    elif echo "$subject" | grep -qiE "Claude|Cursor|Codex|MCP|Opus|Haiku|Sonnet|vibe cod|agent|automation|agentic|v0|Lovable|Bolt|Replit"; then
        category="AI Tools & Workflows"

    # AI Strategy (check before general Lenny fallback)
    elif echo "$from" | grep -qi "natesnewsletter"; then
        category="AI Strategy"
    elif echo "$subject" | grep -qiE "strategy|AGI|bottleneck|constraint|Andreessen|Altman|Amodei|Hassabis|foundation model|scaling law"; then
        category="AI Strategy"

    # Product & Growth
    elif echo "$from" | grep -qi "aakashgupta\|aakashg\.com"; then
        category="Product & Growth"
    elif echo "$subject" | grep -qiE "PM OS|product|growth|framework|OKR|roadmap|PRD|interview|career|hiring|activation|retention|PMF|user research"; then
        category="Product & Growth"

    # Leadership & Life
    elif echo "$subject" | grep -qiE "Dr\. Becky|parenting|leadership|work-life|emotional|resilience|boundaries|culture|team dynamics"; then
        category="Leadership & Life"

    # Community & Culture
    elif echo "$subject" | grep -qi "Community Wisdom"; then
        category="Community & Culture"
    elif echo "$subject" | grep -qi "Weekender"; then
        category="Community & Culture"
    elif echo "$subject" | grep -qiE "Slack thread|community|meetup|event|best threads"; then
        category="Community & Culture"
    fi

    # Add category to newsletter object
    echo "$newsletter" | jq --arg cat "$category" '. + {topic: $cat}'
done | jq -s '.' > "$OUTPUT"

COUNT=$(jq 'length' "$OUTPUT")
echo "✓ Categorized $COUNT newsletters" >&2

# Show category breakdown
echo "" >&2
echo "Category breakdown:" >&2
jq -r 'group_by(.topic) | map({topic: .[0].topic, count: length}) | .[] | "  \(.topic): \(.count)"' "$OUTPUT" >&2

exit 0
