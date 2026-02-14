---
name: network-scan
description: Compare your network groups by scanning for a role or criteria across multiple groups. Surfaces cross-group overlaps and per-group statistics.
---

# Network Scan

**Purpose:** Search for the same criteria across multiple Happenstance groups to compare your networks. Answers questions like "Which of my groups has the most AI engineers?" or "Who appears in multiple groups?" Provides per-group stats, cross-group overlap analysis, and ranked results.

**Cost formula:** 2 * G credits (G = number of groups searched)

## When to Use This Skill

Use when:
- User asks "Which of my groups has the most [role]?"
- User wants to compare networks or groups side by side
- User asks "Who in my network is a [role]?" across all groups
- User wants cross-group analysis (people appearing in multiple groups)

Don't use when:
- User wants to search a single group or their whole network (use `/happenstance` search)
- User wants exhaustive results with export (use `/batch-prospect`)
- User wants mutual connection analysis (use `/warm-intro`)

## Workflow

### STEP 1: Parse the Request

Extract:
- **Search query** (required): the role, criteria, or description to search for
- **Groups** (optional): specific groups to scan, or "all"

### STEP 2: Fetch Groups

Call `mcp__happenstance__get-groups` to list available groups.

Present to user for selection:
```
Your groups:
1. [Group Name] ([member_count] members)
2. [Group Name] ([member_count] members)
3. ...

Which groups should I scan? (Enter numbers, or "all")
```

If user already specified groups, skip this prompt.

### STEP 3: Credit Check

Call `mcp__happenstance__get-credits`.

Calculate cost: 2 * number_of_groups.

```
Scanning [G] groups will cost [2*G] credits (2 per group).
You currently have [balance] credits. Proceed?
```

### STEP 4: Search Each Group

For each selected group, call `mcp__happenstance__search-network` with:
- `query`: the search query
- `includeFriends`: false (search within group only)
- `includeConnections`: false
- `groups`: [current_group_id]

Launch all searches before polling (they run concurrently on the server).

### STEP 5: Poll All Searches

Poll `mcp__happenstance__get-search-results` for each search ID, cycling through them every 5-10 seconds until all are complete.

### STEP 6: Cross-Reference and Analyze

Build analysis across all group results:

1. **Per-group counts:** How many matches per group
2. **Cross-group overlap:** People appearing in multiple groups (match by name + company)
3. **Per-group avg score:** Average `weighted_traits_score` per group
4. **Unique-to-group:** People who only appear in one group

### STEP 7: Present Comparison

```
## Network Scan: "[query]"

Scanned [G] groups. Credits used: [2*G].

### Group Comparison

| Group | Matches | Avg Score | Unique |
|---|---|---|---|
| [Group A] | [count] | [avg_score] | [unique_count] |
| [Group B] | [count] | [avg_score] | [unique_count] |
| ... | ... | ... | ... |

### Cross-Group Overlap

[N] people appear in multiple groups:

| Person | Title | Groups | Best Score |
|---|---|---|---|
| [Name] | [Title at Company] | [Group A], [Group B] | [highest_score] |
| ... | ... | ... | ... |

### Top Matches by Group

**[Group A]** ([count] matches):
1. **[Name]** - [Title] at [Company] (score: [score])
2. **[Name]** - [Title] at [Company] (score: [score])
3. ...

**[Group B]** ([count] matches):
1. ...

Would you like to:
- Research any of these people? (1 credit each)
- Run a deep search on a specific group?
- Export results?
```

## Error Handling

- **No groups available:** Inform user they need to create groups on Happenstance first
- **Some groups fail:** Report partial results, note which groups failed
- **Zero results for a group:** Include the group in the comparison with 0 count

## Best Practices

1. Launch all group searches before polling to maximize parallelism
2. Use consistent matching criteria for cross-group overlap (name + company is reliable)
3. Present the comparison table first for quick scanning, details below
4. Highlight cross-group people since they're often the most well-connected
5. For large groups, focus the top-matches list on the top 5 per group
