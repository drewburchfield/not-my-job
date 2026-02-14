---
name: batch-prospect
description: Exhaustive network search with find-more pagination and export to CSV or markdown. Designed for prospecting with configurable depth and safety caps.
---

# Batch Prospect

**Purpose:** Run an exhaustive search for people matching a query, paginating through all available results using find-more, and export the results to CSV, markdown table, or JSON. Designed for prospecting workflows where you need a complete list, not just the first page.

**Cost formula:** 2 + (2 * F) + N credits
- 2 for initial search
- 2 per find-more round (F rounds)
- 1 per optional research (N people)

**Safety:** Hard cap on find-more rounds (default 3, max 10). User confirms at each cost threshold.

## When to Use This Skill

Use when:
- User wants "everyone matching X" or "give me a full list"
- User wants results exported to CSV or a spreadsheet-ready format
- User wants to prospect a large number of people matching criteria
- User says "exhaustive search" or "find all"

Don't use when:
- User wants a quick search with just the first page (use `/happenstance` search)
- User wants search + research on top matches (use `/deep-search`)
- User wants to compare groups (use `/network-scan`)

## Workflow

### STEP 1: Parse the Request

Extract:
- **Search query** (required): the natural language criteria
- **Scope**: friends, connections, groups
- **Max find-more rounds** (optional, default 3, max 10)
- **Export format** (optional): csv, markdown, json (default: markdown)
- **Research top N** (optional, default 0): how many top matches to research

### STEP 2: Credit Check and Cost Estimate

Call `mcp__happenstance__get-credits`.

Present worst-case cost:
```
Batch prospect estimate:
- Initial search: 2 credits
- Up to [max_rounds] find-more rounds: up to [2 * max_rounds] credits
- Research top [N]: [N] credits
- Worst case total: [2 + 2*max_rounds + N] credits

You currently have [balance] credits.
I'll confirm with you after each find-more round. Proceed with the initial search?
```

### STEP 3: Initial Search

Call `mcp__happenstance__search-network` with:
- `query`: the search query
- `includeFriends`: true (unless specified)
- `includeConnections`: true (unless specified)
- `groups`: if specified

### STEP 4: Poll Initial Results

Poll `mcp__happenstance__get-search-results` until complete.

Accumulate results into a running list.

Report progress:
```
Page 1: [count] results found. Total so far: [total].
[has_more ? "More results available." : "No more results."]
```

### STEP 5: Find-More Loop

If `has_more` is true and rounds remaining > 0:

```
[total] results so far. Fetch more? (2 more credits, [rounds_remaining] rounds left)
```

If user confirms:
1. Call `mcp__happenstance__find-more-results` with the search ID
2. Poll `mcp__happenstance__get-search-results` with the returned page_id
3. Append new results to the accumulated list
4. Decrement rounds remaining
5. Report progress and repeat

**Fallback:**
```bash
source "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts/lib.sh"
FIND_MORE_RESULT=$("$API_SCRIPT" find-more "$SEARCH_ID")
PAGE_ID=$(echo "$FIND_MORE_RESULT" | jq -r '.page_id')
poll_search "$SEARCH_ID" "$PAGE_ID"
```

### STEP 6: Optional Research

If user requested research on top N:
1. Sort accumulated results by `weighted_traits_score`
2. Present top N for confirmation
3. Research each selected person
4. Append research profiles to results

### STEP 7: Export

Use the export script to convert accumulated results:

```bash
cd "${CLAUDE_PLUGIN_ROOT}/skills/batch-prospect/scripts"
echo '<json_results>' | ./export-results.sh --format csv > results.csv
echo '<json_results>' | ./export-results.sh --format markdown
echo '<json_results>' | ./export-results.sh --format json > results.json
```

Present the export to the user:
- **CSV:** Write to a file and tell the user the path
- **Markdown:** Display inline as a table
- **JSON:** Write to a file and tell the user the path

```
## Batch Prospect: "[query]"

Total results: [count] across [pages] pages.
Credits used: [actual_cost].

[export table or file path]

[If researched:]
### Detailed Profiles
[research profiles for top N]
```

## Error Handling

- **Search returns 0 results:** Inform user, suggest different criteria
- **Find-more returns no new results:** Stop the loop, export what we have
- **Credit exhaustion mid-loop:** Stop, export accumulated results, inform user
- **Export script fails:** Fall back to displaying results as a markdown table inline

## Best Practices

1. Always confirm with user before each find-more round (credit awareness)
2. Enforce the hard cap on find-more rounds (default 3, never exceed 10)
3. Show running total of results and credits after each round
4. Export to the user's preferred format; default to markdown for inline display
5. If the result set is very large (100+), prefer CSV export over inline markdown
6. Sort by weighted_traits_score for consistent ordering
