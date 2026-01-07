#!/bin/bash
# verify_coverage.sh - Verify ALL extracted merchants appear in the output
# Usage: ./verify_coverage.sh <extracted_merchants.json> <output_file.md>
#
# This script MUST be run before finalizing the subscription audit report.
# It ensures no merchants were skipped during the identification phase.
#
# Pattern-based: Checks EVERY extracted merchant, not a hardcoded list.

set -e

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

EXTRACTED_FILE="${1:?Usage: $0 <extracted_merchants.json> <output_file.md>}"
OUTPUT_FILE="${2:?Usage: $0 <extracted_merchants.json> <output_file.md>}"

if [[ ! -f "$EXTRACTED_FILE" ]]; then
    echo "ERROR: Extraction file not found: $EXTRACTED_FILE" >&2
    exit 1
fi

if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "ERROR: Output file not found: $OUTPUT_FILE" >&2
    exit 1
fi

echo "=== Coverage Verification ===" >&2
echo "Extraction: $EXTRACTED_FILE" >&2
echo "Output: $OUTPUT_FILE" >&2
echo "" >&2

MISSING=()
FOUND=()
SKIPPED=()

# Extract ALL merchant names from the JSON
# Handle both Privacy.com format and others
MERCHANTS=$(grep -oE '"name":\s*"[^"]+"' "$EXTRACTED_FILE" 2>/dev/null | \
    sed 's/"name":\s*"//;s/"$//' | \
    sort -u || echo "")

if [[ -z "$MERCHANTS" ]]; then
    echo "WARNING: No merchants found in extraction file" >&2
    echo "VERIFICATION_STATUS: SKIPPED"
    echo "REASON: No merchants in extraction"
    exit 0
fi

TOTAL=$(count_lines "$MERCHANTS")
echo "Checking $TOTAL extracted merchants..." >&2
echo "" >&2

while IFS= read -r merchant; do
    # Skip empty lines
    [[ -z "$merchant" ]] && continue

    # Skip known false positives (non-subscription merchants)
    # Uses shared FALSE_POSITIVES from config.sh
    if echo "$merchant" | grep -qE "$FALSE_POSITIVES"; then
        SKIPPED+=("$merchant (non-subscription)")
        continue
    fi

    # Use MIN_MATCH_LENGTH characters for matching (default 10, from config.sh)
    # This prevents false positives from very short prefixes
    local_match_len=${MIN_MATCH_LENGTH:-10}

    # Calculate actual prefix length (use full name if shorter than minimum)
    merchant_len=${#merchant}
    if [[ $merchant_len -lt $local_match_len ]]; then
        SHORT="$merchant"
    else
        SHORT="${merchant:0:$local_match_len}"
    fi

    # Use grep -F for literal string matching (no regex interpretation)
    # This handles special characters like *, ., etc. safely
    if grep -qiF "$SHORT" "$OUTPUT_FILE" 2>/dev/null; then
        FOUND+=("$merchant")
        echo "✓ $merchant" >&2
    else
        MISSING+=("$merchant")
        echo "✗ $merchant - NOT FOUND (searched for: '$SHORT')" >&2
    fi
done <<< "$MERCHANTS"

echo "" >&2
echo "=== VERIFICATION RESULTS ===" >&2
echo "" >&2
echo "Total extracted: $TOTAL" >&2
echo "Found in output: ${#FOUND[@]}" >&2
echo "Missing: ${#MISSING[@]}" >&2
echo "Skipped (non-subscription): ${#SKIPPED[@]}" >&2

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "" >&2
    echo "!!! COVERAGE FAILURE !!!" >&2
    echo "" >&2
    echo "The following merchants were extracted but NOT found in output:" >&2
    echo "" >&2
    for m in "${MISSING[@]}"; do
        echo "  - $m" >&2
    done
    echo "" >&2
    echo "ACTION REQUIRED:" >&2
    echo "1. Identify each missing merchant (use mapping, reasoning, or web search)" >&2
    echo "2. Add to output file with appropriate categorization" >&2
    echo "3. Run this verification again" >&2
    echo "" >&2

    # Machine-readable output
    echo "VERIFICATION_STATUS: FAILED"
    echo "MISSING_COUNT: ${#MISSING[@]}"
    echo "MISSING_MERCHANTS:"
    for m in "${MISSING[@]}"; do
        echo "  - $m"
    done
    exit 1
else
    echo "" >&2
    echo "✓ ALL subscription-like merchants are accounted for." >&2
    echo "" >&2

    # Machine-readable output
    echo "VERIFICATION_STATUS: PASSED"
    echo "FOUND_COUNT: ${#FOUND[@]}"
    echo "SKIPPED_COUNT: ${#SKIPPED[@]}"
    exit 0
fi
