---
name: warm-intro
description: Find mutual connections who can introduce you to people at a target company or in a target role. Analyzes your network for the best connectors.
---

# Warm Intro

**Purpose:** Identify who in your network can introduce you to people at a specific company, in a specific role, or matching other criteria. Builds a ranked list of your best connectors based on how many target matches they connect to and their affinity scores.

**Cost formula:** 2 credits base (search), +1 per optional research on a connector or target

## When to Use This Skill

Use when:
- User asks "Who do I know at [Company]?"
- User wants warm introductions to people matching a description
- User asks "Who can introduce me to [person/role/company]?"
- User wants to find mutual connections for networking

Don't use when:
- User wants a full profile on a known person (use `/happenstance` research)
- User wants to search without focusing on mutuals (use `/happenstance` search)
- User wants a meeting briefing (use `/meeting-prep`)

## Workflow

### STEP 1: Parse the Request

Extract:
- **Target criteria** (required): company name, role, description, or specific person
- **Scope**: which connections to include (default: friends + connections)

### STEP 2: Credit Check

Call `mcp__happenstance__get-credits`.

Present cost:
```
This warm intro search will cost 2 credits for the network search.
Optional: +1 credit per person you'd like to research further.
You currently have [balance] credits. Proceed?
```

### STEP 3: Search Network with Mutual Focus

Call `mcp__happenstance__search-network` with:
- `query`: the target criteria
- `includeFriends`: true
- `includeConnections`: true
- `groups`: if user specified

The key data is in the `mutuals` array within each search result.

### STEP 4: Poll for Results

Call `mcp__happenstance__get-search-results` every 5-10 seconds until `COMPLETED`.

### STEP 5: Build Connector Index

From all search results, extract the `mutuals` arrays and build a reverse index:

```
For each result person:
  For each mutual in result.mutuals:
    connector_map[mutual.name] += {
      target: result person,
      affinity_score: mutual.affinity_score (if available)
    }
```

Rank connectors by:
1. **Number of target matches** they connect to (more = better connector)
2. **Average affinity score** across connections (higher = stronger relationships)

### STEP 6: Present Connector Rankings

```
## Warm Intro Analysis: "[target criteria]"

Found [total_results] people matching your criteria.
[unique_connectors] mutual connections identified.

### Your Best Connectors

1. **[Connector Name]** - connects you to [N] matches
   Targets: [Person A] ([Title]), [Person B] ([Title])
   Avg affinity: [score]

2. **[Connector Name]** - connects you to [N] matches
   Targets: [Person A] ([Title])
   Avg affinity: [score]

3. ...

### All Matches by Connector

| Connector | Target Person | Target Role | Affinity |
|---|---|---|---|
| [name] | [name] | [title at company] | [score] |
| ... | ... | ... | ... |

Would you like to:
- Research a connector for their full profile? (1 credit each)
- Research a target person? (1 credit each)
- See the full search results without mutual focus?
```

### STEP 7: Optional Research

If the user wants to research a connector or target, call `mcp__happenstance__research-person` and poll for results. Present the full profile.

## Error Handling

- **No mutual connections found:** This means the search matched people but none share mutual connections. Present the raw search results instead and explain that no mutual connectors were found.
- **Zero search results:** Suggest broadening the criteria or checking different groups.

## Best Practices

1. Always search with both `--friends` and `--connections` for maximum mutual coverage
2. Highlight connectors who bridge to multiple targets (they're your best intro path)
3. Include affinity scores when available to indicate relationship strength
4. Suggest the "best path" (highest-ranked connector to highest-ranked target)
5. Offer to research the top connector so user has context before reaching out
