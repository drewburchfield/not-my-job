#!/bin/bash
# list_subscription_merchants.sh - List ONLY subscription-like merchants from CSV
# Usage: ./list_subscription_merchants.sh <csv_file>
#
# Filters out known non-subscription merchants (shopping, food, etc.)
# Outputs a checklist that Claude MUST process item-by-item.

set -e

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

CSV_FILE="${1:?Usage: $0 <csv_file>}"

# Validate CSV file
if ! validate_csv "$CSV_FILE"; then
    exit 1
fi

echo "=== Subscription-Like Privacy.com Merchants ==="
echo "CSV: $CSV_FILE"
echo "Date: $(date +%Y-%m-%d)"
echo ""
echo "The following merchants appear to be subscriptions and MUST be identified:"
echo ""

# Extract all Privacy.com merchants
ALL_MERCHANTS=$(grep -oE "PwP [^\"]+Privacycom" "$CSV_FILE" 2>/dev/null | \
    sed 's/Privacycom.*//' | sed 's/PwP //' | \
    sort | uniq -c | sort -rn || echo "")

# Filter and display
echo "| # | Merchant (truncated) | Charges | Status |"
echo "|---|---------------------|---------|--------|"

COUNT=0
while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    CHARGES=$(echo "$line" | awk '{print $1}')
    MERCHANT=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ //')

    # Skip false positives (uses shared FALSE_POSITIVES from config.sh)
    if echo "$MERCHANT" | grep -qE "$FALSE_POSITIVES"; then
        continue
    fi

    # Skip if empty
    if [[ -z "$MERCHANT" ]]; then
        continue
    fi

    COUNT=$((COUNT + 1))
    echo "| $COUNT | $MERCHANT | $CHARGES | [ ] TODO |"

done <<< "$ALL_MERCHANTS"

echo ""
echo "=== TOTAL: $COUNT subscription-like merchants to identify ==="
echo ""
echo "INSTRUCTIONS FOR CLAUDE:"
echo "1. Process EACH merchant in the table above"
echo "2. For each merchant:"
echo "   - Identify the full service name"
echo "   - Look up typical pricing"
echo "   - Categorize as Keep/Cancel/Investigate"
echo "3. Mark as [x] DONE when processed"
echo "4. Run verify_coverage.sh before generating final report"
echo ""
echo "DO NOT skip merchants. Single charges may be annual subscriptions."
