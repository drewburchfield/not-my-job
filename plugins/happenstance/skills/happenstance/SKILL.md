---
name: happenstance
description: Research people and search your professional network using the Happenstance API. Supports person research with detailed profiles, natural language network search, and paginated results. Routes to specialized derivative skills for compound workflows.
---

# Happenstance

**Purpose:** Research specific people or search your professional network using Happenstance's AI-powered API. Returns detailed profiles, employment history, social links, and mutual connections. Also serves as the routing hub for derivative workflow skills.

## Routing Decision Tree

Before executing, determine the best skill for the user's intent:

| User Intent | Route To | Command |
|---|---|---|
| Research a specific person | **This skill** (Phase 3A below) | `/happenstance` |
| Search network for people matching criteria | **This skill** (Phase 3B below) | `/happenstance` |
| Check credits or list groups | **This skill** (Phase 2) | `/happenstance` |
| Search AND auto-research top matches | `happenstance:deep-search` | `/deep-search` |
| Find mutual connections for warm intros | `happenstance:warm-intro` | `/warm-intro` |
| Prepare a briefing for a meeting with someone | `happenstance:meeting-prep` | `/meeting-prep` |
| Compare groups or scan networks for a role | `happenstance:network-scan` | `/network-scan` |
| Exhaustive search with export to CSV/markdown | `happenstance:batch-prospect` | `/batch-prospect` |

If the user's request maps to a derivative skill, tell them which command to use and offer to invoke it.

## MCP Tools (Primary)

When the Happenstance MCP server is connected, use MCP tools directly. These are the preferred execution method.

| Tool | Purpose | Credits |
|---|---|---|
| `mcp__happenstance__search-network` | Start a network search | 2 |
| `mcp__happenstance__get-search-results` | Poll for search results | 0 |
| `mcp__happenstance__find-more-results` | Get additional search results | 2 |
| `mcp__happenstance__research-person` | Start a person research | 1 |
| `mcp__happenstance__get-research-results` | Poll for research results | 0 |
| `mcp__happenstance__get-groups` | List available groups | 0 |
| `mcp__happenstance__get-credits` | Check credit balance | 0 |

See `references/mcp-tools.md` for full parameter details and polling patterns.

## Shell Script Fallback

If MCP tools are unavailable, use the shell scripts:

```bash
cd "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts"
./happenstance-api.sh <command> [args]
```

The `lib.sh` helper provides shared polling and credit-check functions for compound workflows.

## Dependencies

**MCP (preferred):** Authentication handled automatically via OAuth 2.0 (browser login on first use). No API key needed.

**Shell script fallback:**
1. `HAPPENSTANCE_API_KEY` environment variable set with a valid API key
   - Get your key at https://happenstance.ai/settings/api
2. `curl` - for API requests (pre-installed on macOS/Linux)
3. `jq` - for JSON processing (`brew install jq`)
4. `bc` - for arithmetic in credit checks (pre-installed on macOS)

## Workflow Overview

Happenstance has two primary workflows, both asynchronous:

```
Research: Submit description -> Poll for results -> Display profile
Search:   Submit query -> Poll for results -> Display matches -> (optional) Find more
```

**Credit costs:**
- `/research` = 1 credit (charged on completion)
- `/search` = 2 credits
- `/search/:id/find-more` = 2 credits

## Implementation

### PHASE 1: Determine Intent

Ask the user what they want to do:
1. **Research a person** - provide a description (name, company, title, social handles)
2. **Search their network** - provide a natural language query
3. **Check usage/credits** - view balance and history
4. **List groups** - see available contact groups

If their intent maps to a derivative skill (deep search, warm intro, meeting prep, network scan, batch prospect), route them there instead.

### PHASE 2: Check Credits

Before expensive operations, check the user's credit balance:

**MCP:** Call `mcp__happenstance__get-credits` and check `balance_credits` and `has_credits`.

**Fallback:**
```bash
cd "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts"
./happenstance-api.sh usage | jq '.balance_credits, .has_credits'
```

If `has_credits` is false, inform the user they need to purchase credits at https://happenstance.ai/settings/api.

### PHASE 3A: Research a Person

**MCP:** Call `mcp__happenstance__research-person` with the description. Extract the ID, then poll `mcp__happenstance__get-research-results` every 5-10 seconds until status is not `RUNNING`.

**Fallback:**
```bash
cd "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts"
RESULT=$(./happenstance-api.sh research "Full Name, Title at Company, @twitter_handle")
RESEARCH_ID=$(echo "$RESULT" | jq -r '.id')
echo "Research ID: $RESEARCH_ID"
```

**Tips for better results:** Include as many identifiers as possible:
- Full name
- Current company and title
- Twitter/X handle
- LinkedIn URL
- Location

**Poll for results (every 5-10 seconds):**

```bash
./happenstance-api.sh poll-research "$RESEARCH_ID"
```

**Status values:**
- `RUNNING` - still processing, poll again
- `COMPLETED` - results ready in `profile` field
- `FAILED` - could not find the person
- `FAILED_AMBIGUOUS` - description matched multiple people; ask user to be more specific

**Present results:** Format the profile data clearly, highlighting:
- Name, title, company, location
- Employment history
- Education
- Notable projects and writings
- Social links
- AI-generated summary

### PHASE 3B: Search Your Network

**MCP:** Call `mcp__happenstance__search-network` with query, includeFriends, includeConnections, and optional groups array. (See `references/mcp-tools.md` for the full MCP-to-REST parameter mapping.) Poll `mcp__happenstance__get-search-results` until complete.

**Fallback:**
```bash
cd "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts"
RESULT=$(./happenstance-api.sh search "Software engineers in San Francisco" --friends --connections)
SEARCH_ID=$(echo "$RESULT" | jq -r '.id')
echo "Search ID: $SEARCH_ID"
```

**Flags:**
- `--friends` - include friends' connections
- `--connections` - include your direct connections
- `--groups '["group_id_1"]'` - search specific groups

To list available groups first, call `mcp__happenstance__get-groups` or:
```bash
./happenstance-api.sh groups
```

**Poll for results (every 5-10 seconds):**

```bash
./happenstance-api.sh poll-search "$SEARCH_ID"
```

**Present results:** Format each person clearly:
- Name, current title and company
- Brief summary
- Relevance scores (`weighted_traits_score`, if present)
- Mutual connections
- Social links

**If `has_more` is true,** ask the user if they want additional results:

**MCP:** Call `mcp__happenstance__find-more-results`, then poll `mcp__happenstance__get-search-results` with the returned page_id.

**Fallback:**
```bash
./happenstance-api.sh find-more "$SEARCH_ID"
# Then poll with the page_id for the new results
./happenstance-api.sh poll-search "$SEARCH_ID" "$PAGE_ID"
```

### PHASE 4: Format and Present

Present results in a clean, scannable format. For research profiles, use structured sections. For search results, use a table or numbered list with key details.

**Research profile format:**
```
## [Person Name]
**[Title] at [Company]** | [Location]

### Summary
[AI-generated summary]

### Employment
- [Company] - [Title] (dates)
- ...

### Education
- [School] - [Degree] (dates)

### Links
- Twitter: [url]
- LinkedIn: [url]
```

**Search results format:**
```
### Results for "[query]"

1. **[Name]** - [Title] at [Company]
   [Brief summary]
   Score: [weighted_traits_score] | [social links]

2. ...
```

## Error Handling

### 401 Unauthorized
```
Error: Invalid or missing API key
Fix: Check HAPPENSTANCE_API_KEY is set correctly
     Get a new key at https://happenstance.ai/settings/api
```

### 402 Insufficient Credits
```
Error: Not enough credits for this operation
Fix: Purchase credits at https://happenstance.ai/settings/api
     Research costs 1 credit, Search costs 2 credits
```

### 429 Too Many Requests
```
Error: Too many concurrent research requests (max 10)
Fix: Wait for current research requests to complete before starting new ones
```

### FAILED_AMBIGUOUS (Research)
```
Error: Description matched multiple people
Fix: Ask the user for more specific details (full name + company + social handle)
```

## Reference Files

### api-reference.md
Complete API endpoint documentation with request/response schemas. Consult when you need exact parameter names or response field details.

### mcp-tools.md
MCP tool name mapping, parameters, and polling patterns. Consult when calling MCP tools directly.

## Best Practices

1. Always include multiple identifiers when researching a person (name + company + social handle)
2. Check credits before starting expensive operations
3. Poll every 5-10 seconds; do not flood the API
4. For search, enable both `--friends` and `--connections` unless the user specifies otherwise
5. When `has_more` is true, ask before fetching more (it costs 2 additional credits)
6. Present results in clean, scannable formats
7. If research fails as ambiguous, ask the user for more identifying details
8. Prefer MCP tools over shell scripts when both are available
9. Route compound workflows to the appropriate derivative skill

## Verification Checklist

- [ ] Authentication available (MCP connected, or HAPPENSTANCE_API_KEY set for shell fallback)
- [ ] Request was submitted successfully (got an ID back)
- [ ] Polling completed (status is no longer RUNNING)
- [ ] Results were formatted and presented to the user
- [ ] Credits were not wasted on failed requests

## Example Session

```
User: /happenstance
Claude: What would you like to do?
  1. Research a specific person
  2. Search your network
  3. Check credits/usage

User: Research Garry Tan from Y Combinator
Claude: Starting research on "Garry Tan, CEO at Y Combinator, @garrytan on Twitter"...
        [polls until complete]
        Here's what I found:

        ## Garry Tan
        **CEO at Y Combinator** | San Francisco, CA

        ### Summary
        [profile summary]

        ### Employment
        - Y Combinator - CEO (2023-present)
        - Initialized Capital - Co-founder (2011-2022)
        ...
```
