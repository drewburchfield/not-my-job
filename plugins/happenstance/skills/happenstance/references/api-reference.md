# Happenstance API Reference

## Base URL

`https://api.happenstance.ai/v1`

## Authentication

All requests require a Bearer token:
```
Authorization: Bearer YOUR_API_KEY
```

**Note:** This reference documents the REST API field names (snake_case). The MCP tools use camelCase parameter names (e.g., `query` instead of `text`, `includeFriends` instead of `include_friends_connections`). See `mcp-tools.md` for MCP-specific parameter names.

## Endpoints

### Research

#### POST /research
Create a research request for a specific person. Costs 1 credit on completion.

**Request body:**
```json
{
  "description": "Garry Tan (CEO Y Combinator) @garrytan on Twitter"
}
```

**Tip:** Include social URLs, Twitter handles, company, title, and location for more accurate results.

**Response:**
```json
{
  "id": "research_id_here",
  "status": "RUNNING"
}
```

#### GET /research/{research_id}
Poll for research results. Typical completion: 1-3 minutes.

**Status values:** `RUNNING`, `COMPLETED`, `FAILED`, `FAILED_AMBIGUOUS`

**Completed response includes:**
- `profile.person_metadata` - name, location, social URLs
- `profile.employment` - work history
- `profile.education` - education history
- `profile.projects` - notable projects
- `profile.writings` - published content
- `profile.hobbies` - interests
- `profile.summary` - AI-generated summary with source URLs

### Search

#### POST /search
Search your network by natural language. Costs 2 credits.

**Request body:**
```json
{
  "text": "Software engineers in San Francisco",
  "include_friends_connections": true,
  "include_my_connections": true,
  "group_ids": ["optional_group_id"]
}
```

**Response:**
```json
{
  "id": "search_id_here",
  "status": "RUNNING"
}
```

#### GET /search/{search_id}
Poll for search results. Typical completion: 30-60 seconds. Returns up to 30 results at a time.

**Optional query param:** `page_id` for pagination.

**Completed response includes:**
- `results` - array of person objects (name, current_title, current_company, summary, weighted_traits_score, socials {linkedin_url, twitter_url}, mutuals)
- `has_more` - boolean indicating additional results available
- `url` - direct link to results on Happenstance

#### POST /search/{search_id}/find-more
Fetch additional results when `has_more` is true. Costs 2 credits.

**Response:**
```json
{
  "page_id": "new_page_id"
}
```

Poll `GET /search/{search_id}?page_id={page_id}` for the new results.

### Groups

#### GET /groups
List your accessible groups (contact lists, teams, etc.)

### Usage

#### GET /usage
Check credit balance, purchase history, and usage records.

**Response includes:**
- `balance_credits` - current credit balance (can be negative)
- `has_credits` - boolean
- `purchases` - purchase history
- `usage` - usage history

## Error Handling

Errors follow RFC 7807 Problem Details format (`application/problem+json`):
```json
{
  "type": "https://developer.happenstance.ai/errors/insufficient-credits",
  "title": "Insufficient Credits",
  "status": 402,
  "detail": "You need at least 2 credits to perform a search.",
  "instance": "/search"
}
```

**Status codes:**
- `400` - Bad request
- `401` - Unauthorized (invalid/missing API key)
- `402` - Insufficient credits
- `403` - Forbidden
- `404` - Not found
- `410` - Gone (expired resource)
- `422` - Unprocessable entity
- `429` - Too many requests (max 10 concurrent research requests)
- `500` - Internal server error
- `503` - Service unavailable

## Polling

Both research and search are asynchronous. Poll every 5-10 seconds until status is no longer `RUNNING`.
