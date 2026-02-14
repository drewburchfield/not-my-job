# Happenstance MCP Tools Reference

The Happenstance MCP server exposes 7 tools via HTTP transport at `https://happenstance.ai/mcp`. When the plugin is enabled, these tools are available to Claude as `mcp__happenstance__<tool-name>`.

## Authentication

The MCP server uses **OAuth 2.0 with PKCE** via Clerk (`clerk.happenstance.ai`). Claude Code handles this automatically:
1. On first connection, a browser window opens for Clerk login
2. After authenticating, Claude Code receives a JWT
3. The JWT is used for all subsequent MCP calls

The `.mcp.json` uses bare HTTP transport (no static auth headers). The REST API (`api.happenstance.ai`) used by shell scripts has separate auth via `HAPPENSTANCE_API_KEY` environment variable.

## Tool Inventory

| MCP Tool Name | API Endpoint | Credits | Async? |
|---|---|---|---|
| `mcp__happenstance__search-network` | POST /search | 2 | Yes, returns search ID |
| `mcp__happenstance__get-search-results` | GET /search/{id} | 0 | Poll until status != RUNNING |
| `mcp__happenstance__find-more-results` | POST /search/{id}/find-more | 2 | Returns page_id, poll with get-search-results |
| `mcp__happenstance__research-person` | POST /research | 1 | Yes, returns research ID |
| `mcp__happenstance__get-research-results` | GET /research/{id} | 0 | Poll until status != RUNNING |
| `mcp__happenstance__get-groups` | GET /groups | 0 | No |
| `mcp__happenstance__get-credits` | GET /usage | 0 | No |

## Tool Parameters

### search-network

```json
{
  "query": "Software engineers in San Francisco",
  "includeFriends": true,
  "includeConnections": true,
  "includeGroups": true,
  "groups": ["optional_group_id"]
}
```

**Parameter mapping (MCP vs REST API):**
| MCP Parameter | REST API Field | Notes |
|---|---|---|
| `query` | `text` | Required. Natural language search query |
| `includeFriends` | `include_friends_connections` | Include friends' connections |
| `includeConnections` | `include_my_connections` | Include your direct connections |
| `includeGroups` | N/A | Include group connections (default true) |
| `groups` | `group_ids` | Optional array of group IDs |

Returns `{ "id": "search_id", "status": "RUNNING" }`.

### get-search-results

```json
{
  "searchId": "the_search_id",
  "pageId": "optional_page_id"
}
```

Returns search results when status is `COMPLETED`. Key fields:
- `results[]` - array of person matches (name, current_title, current_company, summary, weighted_traits_score, socials {linkedin_url, twitter_url}, mutuals)
- `has_more` - boolean, if true call find-more-results
- `url` - link to view on Happenstance

### find-more-results

```json
{
  "searchId": "the_search_id"
}
```

Returns `{ "page_id": "new_page_id" }`. Poll get-search-results with this page_id.

### research-person

```json
{
  "description": "Garry Tan, CEO at Y Combinator, @garrytan on Twitter"
}
```

Returns `{ "id": "research_id", "status": "RUNNING" }`.

### get-research-results

```json
{
  "researchId": "the_research_id"
}
```

Status values: `RUNNING`, `COMPLETED`, `FAILED`, `FAILED_AMBIGUOUS`.

On completion, returns full profile:
- `profile.person_metadata` - name, location, social URLs
- `profile.employment` - work history
- `profile.education` - education history
- `profile.projects` - notable projects
- `profile.writings` - published content
- `profile.hobbies` - interests
- `profile.summary` - AI-generated summary

### get-groups

No parameters. Returns array of groups with `id`, `name`, `member_count`.

### get-credits

No parameters. Returns:
- `balance_credits` - current credit count
- `has_credits` - boolean
- `purchases` - purchase history
- `usage` - usage history

## Polling Pattern

For async tools (search-network, research-person), follow this pattern:

1. Call the initiating tool (search-network or research-person)
2. Extract the ID from the response
3. Wait 5-10 seconds
4. Call the corresponding get-results tool with the ID
5. If status is `RUNNING`, go to step 3
6. If status is `COMPLETED`, process results
7. If status is `FAILED` or `FAILED_AMBIGUOUS`, handle error

## Shell Script Fallback

For batch operations or use outside Claude, the same operations are available via:
```bash
${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts/happenstance-api.sh <command> [args]
```

See `happenstance-api.sh help` for commands. The `lib.sh` helper provides shared polling and credit-check functions.
