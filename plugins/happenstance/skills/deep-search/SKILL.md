---
name: deep-search
description: Search your professional network and automatically research the top matches. Combines network search with person research into a single compound workflow.
---

# Deep Search

**Purpose:** Find people matching a query in your professional network, then automatically pull full research profiles on the best matches. Saves time by combining search + research into one workflow.

**Cost formula:** 2 + N credits (2 for search, 1 per person researched, default N=3)

## When to Use This Skill

Use when:
- User wants to find people AND get detailed background on the best matches
- User says "find me [role] at [company] and tell me about them"
- User wants a shortlist with full profiles, not just search results

Don't use when:
- User just wants a list of names (use `/happenstance` search instead)
- User wants to research a specific known person (use `/happenstance` research instead)
- User wants exhaustive results with export (use `/batch-prospect` instead)

## Workflow

### STEP 1: Parse the Query

Extract from the user's request:
- **Search text** (required): the natural language query
- **Scope flags**: friends, connections, specific groups
- **Top N**: how many to research (default 3, user can override)

### STEP 2: Credit Check

Call `mcp__happenstance__get-credits`.

Calculate required credits: `2 + N` (where N is the number to research).

Present the cost to the user:
```
This deep search will cost up to [2 + N] credits:
- 2 credits for the network search
- [N] credits to research the top [N] matches
You currently have [balance] credits. Proceed?
```

If insufficient credits, inform the user and stop.

### STEP 3: Search Network

Call `mcp__happenstance__search-network` with:
- `query`: the search query
- `includeFriends`: true (unless user specified otherwise)
- `includeConnections`: true (unless user specified otherwise)
- `groups`: if user specified groups

**Fallback:**
```bash
cd "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts"
RESULT=$(./happenstance-api.sh search "<query>" --friends --connections)
SEARCH_ID=$(echo "$RESULT" | jq -r '.id')
```

### STEP 4: Poll for Search Results

Call `mcp__happenstance__get-search-results` every 5-10 seconds until status is `COMPLETED`.

### STEP 5: Present Top N for Selection

Sort results by `weighted_traits_score` (descending). Present the top results as a numbered list:

```
### Search Results for "[query]"

Found [total] matches. Here are the top [N] by relevance:

1. **[Name]** - [Title] at [Company] (score: [weighted_traits_score])
   [Brief summary]

2. **[Name]** - [Title] at [Company] (score: [weighted_traits_score])
   [Brief summary]

3. ...

Research these [N] people for full profiles? ([N] credits)
Or pick specific numbers to research (e.g., "1 and 3").
```

Wait for user confirmation. They can:
- Confirm all N
- Select specific ones by number
- Skip research entirely
- Ask to see more search results first

### STEP 6: Research Selected People

For each selected person, call `mcp__happenstance__research-person` with their description (name + title + company + any social handles from search results).

**Fallback:**
```bash
source "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts/lib.sh"
RESULT=$("$API_SCRIPT" research "Name, Title at Company")
RESEARCH_ID=$(echo "$RESULT" | jq -r '.id')
```

### STEP 7: Poll for Research Results

Poll `mcp__happenstance__get-research-results` for each research ID every 5-10 seconds until all are complete.

### STEP 8: Combined Briefing

Present a combined briefing with full profiles for each researched person:

```
## Deep Search: "[query]"

Searched [total] people, researched [N] in depth.
Credits used: [actual_cost]

---

### 1. [Person Name]
**[Title] at [Company]** | [Location]

**Summary:** [AI-generated summary]

**Employment:**
- [Company] - [Title] (dates)
- ...

**Education:**
- [School] - [Degree] (dates)

**Notable:** [projects, writings, hobbies highlights]

**Links:** [Twitter] | [LinkedIn] | [other]

---

### 2. [Person Name]
...
```

## Error Handling

- **Search returns 0 results:** Inform user, suggest broadening the query
- **Research fails (FAILED):** Note which person couldn't be found, continue with others
- **Research fails (FAILED_AMBIGUOUS):** Note ambiguity, suggest user provide more details
- **Insufficient credits mid-workflow:** Stop, report what was completed, suggest purchasing credits

## Best Practices

1. Always confirm cost before proceeding
2. Let the user choose which matches to research (don't auto-research without confirmation)
3. Include social handles from search results in research descriptions for better match accuracy
4. Present results sorted by relevance score
5. If the user wants more than the initial batch, offer to research additional matches
