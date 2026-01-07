#!/bin/bash
# config.sh - Shared configuration for subscription-cleanse scripts
# Source this file in other scripts: source "$(dirname "$0")/config.sh"

# FALSE_POSITIVES: Merchants that are NOT subscriptions
# These are shopping, food, gas, retail, one-time purchases
# Pipe-separated for use with grep -E
# Update this single file to maintain consistency across all scripts
FALSE_POSITIVES="WALMART|WM SUPERCEN|WAL-MART|CHICK-FIL-A|DOMINOS|O'REILLY|CUMBERLAND|WWW COSTCO|MARCOS PIZZ|WINDYGAPRET|TOYOTAPARTS|SWEETWATER|SOUTHWES|POINTS RAPI|ONLINE PASS|ZDIGITIZING|WG PTO|JUSTANOTHER|INTUIT|I3B|CLR\*|CBD MD|BODYGUARDZ"

# Minimum characters for merchant matching (prevents false positives from truncation)
MIN_MATCH_LENGTH=10

# Validate CSV has required structure
# Returns 0 if valid, 1 if invalid
validate_csv() {
    local csv_file="$1"

    if [[ ! -f "$csv_file" ]]; then
        echo "ERROR: File not found: $csv_file" >&2
        return 1
    fi

    # Check file is not empty
    if [[ ! -s "$csv_file" ]]; then
        echo "ERROR: File is empty: $csv_file" >&2
        return 1
    fi

    # Check file has at least 2 lines (header + 1 data row)
    local line_count
    line_count=$(wc -l < "$csv_file" | tr -d ' ')
    if [[ "$line_count" -lt 2 ]]; then
        echo "ERROR: File has no data rows: $csv_file" >&2
        return 1
    fi

    # Check file appears to be CSV (has commas or tabs)
    if ! head -1 "$csv_file" | grep -qE '[,\t]'; then
        echo "ERROR: File doesn't appear to be CSV (no delimiters found): $csv_file" >&2
        return 1
    fi

    return 0
}

# Escape special regex characters for use with grep -E
# Usage: escaped=$(escape_regex "$string")
escape_regex() {
    local string="$1"
    printf '%s' "$string" | sed 's/[[\.*^$()+?{|\\]/\\&/g'
}

# Count non-empty lines (fixes wc -l returning 1 for empty input)
# Usage: count=$(count_lines "$variable")
count_lines() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "0"
    else
        echo "$input" | grep -c . || echo "0"
    fi
}

# Generate JSON array from newline-separated values
# Usage: json_array=$(make_json_array "$values" "format_function")
# format_function should output JSON object for each line
make_json_array() {
    local values="$1"
    local format_fn="$2"

    if [[ -z "$values" ]]; then
        echo ""
        return
    fi

    local first=true
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if $first; then
            first=false
        else
            echo ","
        fi
        if [[ -n "$format_fn" ]]; then
            $format_fn "$line"
        else
            echo "      \"$line\""
        fi
    done <<< "$values"
}
