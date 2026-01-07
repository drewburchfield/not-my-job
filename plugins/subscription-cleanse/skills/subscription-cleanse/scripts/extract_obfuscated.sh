#!/bin/bash
# extract_obfuscated.sh - Deterministic extraction of obfuscated merchants from CSV
# Usage: ./extract_obfuscated.sh <csv_file> [output_file]
#
# This script MUST be run before subscription analysis to ensure ALL merchants are captured.
# Claude CANNOT skip this step - the output is required for validation.

set -e

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

CSV_FILE="${1:?Usage: $0 <csv_file> [output_file]}"
OUTPUT_FILE="${2:-extracted_merchants.json}"

# Validate CSV file
if ! validate_csv "$CSV_FILE"; then
    exit 1
fi

echo "=== Obfuscated Transaction Extraction ===" >&2
echo "CSV: $CSV_FILE" >&2
echo "Output: $OUTPUT_FILE" >&2
echo "" >&2

# Count total obfuscated transactions
# Note: grep -c outputs "0" and exits 1 when no matches, so we handle both cases
TOTAL_OBFUSCATED=$(grep -cE "(PwP.*Privacycom|PAYPAL \*|PP\*|SQ \*|VENMO|CASH APP\*|APPLE.COM/BILL|GOOGLE \*)" "$CSV_FILE" 2>/dev/null) || true
[[ -z "$TOTAL_OBFUSCATED" ]] && TOTAL_OBFUSCATED=0
echo "Total obfuscated transactions found: $TOTAL_OBFUSCATED" >&2

# Extract Privacy.com merchants
echo "" >&2
echo "--- Privacy.com Merchants ---" >&2
PRIVACY_MERCHANTS=$(grep -oE "PwP [^\"]+Privacycom" "$CSV_FILE" 2>/dev/null | sed 's/Privacycom.*//' | sed 's/PwP //' | sort | uniq -c | sort -rn || echo "")

PRIVACY_COUNT=$(count_lines "$PRIVACY_MERCHANTS")
if [[ "$PRIVACY_COUNT" -gt 0 ]]; then
    echo "Found $PRIVACY_COUNT unique Privacy.com merchants:" >&2
    echo "$PRIVACY_MERCHANTS" >&2
else
    echo "No Privacy.com transactions found" >&2
fi

# Extract PayPal merchants
echo "" >&2
echo "--- PayPal Merchants ---" >&2
PAYPAL_MERCHANTS=$(grep -oE "(PAYPAL \*|PP\*)[^,\"]*" "$CSV_FILE" 2>/dev/null | sed 's/PAYPAL \*//;s/PP\*//' | sort | uniq -c | sort -rn || echo "")

PAYPAL_COUNT=$(count_lines "$PAYPAL_MERCHANTS")
if [[ "$PAYPAL_COUNT" -gt 0 ]]; then
    echo "Found $PAYPAL_COUNT unique PayPal merchants:" >&2
    echo "$PAYPAL_MERCHANTS" >&2
else
    echo "No PayPal transactions found" >&2
fi

# Extract Square merchants
echo "" >&2
echo "--- Square Merchants ---" >&2
SQUARE_MERCHANTS=$(grep -oE "SQ \*[^,\"]*" "$CSV_FILE" 2>/dev/null | sed 's/SQ \*//' | sort | uniq -c | sort -rn || echo "")

SQUARE_COUNT=$(count_lines "$SQUARE_MERCHANTS")
if [[ "$SQUARE_COUNT" -gt 0 ]]; then
    echo "Found $SQUARE_COUNT unique Square merchants:" >&2
    echo "$SQUARE_MERCHANTS" >&2
else
    echo "No Square transactions found" >&2
fi

# Extract Apple bundled billing
echo "" >&2
echo "--- Apple Bundled Billing ---" >&2
APPLE_COUNT=$(grep -c "APPLE.COM/BILL" "$CSV_FILE" 2>/dev/null) || true
[[ -z "$APPLE_COUNT" ]] && APPLE_COUNT=0
echo "Apple.com/bill charges: $APPLE_COUNT (check device Settings > Subscriptions for breakdown)" >&2

# Extract Google bundled
echo "" >&2
echo "--- Google Services ---" >&2
GOOGLE_MERCHANTS=$(grep -oE "GOOGLE \*[^,\"]*" "$CSV_FILE" 2>/dev/null | sort | uniq -c | sort -rn || echo "")

GOOGLE_COUNT=$(count_lines "$GOOGLE_MERCHANTS")
if [[ "$GOOGLE_COUNT" -gt 0 ]]; then
    echo "Found $GOOGLE_COUNT unique Google service patterns:" >&2
    echo "$GOOGLE_MERCHANTS" >&2
else
    echo "No Google transactions found" >&2
fi

# Generate JSON output for validation
echo "" >&2
echo "=== Generating structured output ===" >&2

# Helper function to format merchant JSON
format_merchant() {
    local line="$1"
    local charges
    local name
    charges=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
    # Escape quotes in name
    name=$(echo "$name" | sed 's/"/\\"/g')
    echo "      {\"name\": \"$name\", \"charges\": $charges}"
}

# Helper function to format Google merchant JSON (needs GOOGLE * prefix)
format_google_merchant() {
    local line="$1"
    local charges
    local name
    charges=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
    # Escape quotes in name
    name=$(echo "$name" | sed 's/"/\\"/g')
    echo "      {\"name\": \"$name\", \"charges\": $charges}"
}

# Build JSON arrays properly (with commas between elements)
build_json_array() {
    local merchants="$1"
    if [[ -z "$merchants" ]]; then
        echo ""
        return
    fi

    local result=""
    local first=true
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if $first; then
            first=false
        else
            result+=","
            result+=$'\n'
        fi
        result+=$(format_merchant "$line")
    done <<< "$merchants"
    echo "$result"
}

PRIVACY_JSON=$(build_json_array "$PRIVACY_MERCHANTS")
PAYPAL_JSON=$(build_json_array "$PAYPAL_MERCHANTS")
SQUARE_JSON=$(build_json_array "$SQUARE_MERCHANTS")
GOOGLE_JSON=$(build_json_array "$GOOGLE_MERCHANTS")

# Write JSON with proper empty array handling
cat > "$OUTPUT_FILE" << EOF
{
  "extraction_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "csv_file": "$CSV_FILE",
  "total_obfuscated_transactions": $TOTAL_OBFUSCATED,
  "privacy_com": {
    "count": $PRIVACY_COUNT,
    "merchants": [
$(if [[ -n "$PRIVACY_JSON" ]]; then echo "$PRIVACY_JSON" | sed 's/^/  /'; fi)
    ]
  },
  "paypal": {
    "count": $PAYPAL_COUNT,
    "merchants": [
$(if [[ -n "$PAYPAL_JSON" ]]; then echo "$PAYPAL_JSON" | sed 's/^/  /'; fi)
    ]
  },
  "square": {
    "count": $SQUARE_COUNT,
    "merchants": [
$(if [[ -n "$SQUARE_JSON" ]]; then echo "$SQUARE_JSON" | sed 's/^/  /'; fi)
    ]
  },
  "apple_bundled": {
    "count": $APPLE_COUNT,
    "note": "Check device Settings > Subscriptions for breakdown"
  },
  "google": {
    "count": $GOOGLE_COUNT,
    "merchants": [
$(if [[ -n "$GOOGLE_JSON" ]]; then echo "$GOOGLE_JSON" | sed 's/^/  /'; fi)
    ]
  }
}
EOF

echo "" >&2
echo "=== EXTRACTION COMPLETE ===" >&2
echo "Output written to: $OUTPUT_FILE" >&2
echo "" >&2
echo "IMPORTANT: Claude MUST process ALL merchants listed above." >&2
echo "Run verify_coverage.sh after analysis to verify coverage." >&2

# Print summary for Claude to track
echo ""
echo "EXTRACTION_SUMMARY:"
echo "  privacy_com_merchants: $PRIVACY_COUNT"
echo "  paypal_merchants: $PAYPAL_COUNT"
echo "  square_merchants: $SQUARE_COUNT"
echo "  apple_bundled: $APPLE_COUNT"
echo "  google_merchants: $GOOGLE_COUNT"
echo "  total_to_process: $((PRIVACY_COUNT + PAYPAL_COUNT + SQUARE_COUNT + GOOGLE_COUNT))"
