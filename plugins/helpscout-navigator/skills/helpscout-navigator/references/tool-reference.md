# HelpScout MCP Tool Reference

Complete parameter documentation for all 9 HelpScout MCP tools.

---

## 1. searchInboxes

**Purpose:** Get inbox ID from name. ALWAYS call this first when user mentions an inbox.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | yes | - | Inbox name to search for (case-insensitive) |
| `limit` | number | no | 50 | Max results (1-100) |
| `cursor` | string | no | - | Pagination cursor |

**Returns:** Array of inbox objects with `id` (numeric), `name`, `email`, timestamps

**Example:**
```javascript
searchInboxes({ query: "support" })
// Returns: [{ id: 359402, name: "Support", email: "support@company.com" }]
```

---

## 2. listAllInboxes

**Purpose:** List all available inboxes. Quick helper for discovery.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | number | no | 100 | Max results (1-100) |

**Returns:** Array of all inbox objects

**Example:**
```javascript
listAllInboxes({ limit: 50 })
```

---

## 3. searchConversations

**Purpose:** List tickets by time/status. Simple listing without keywords.

**WARNING:** When `query` or `tag` is provided without explicit `status`, defaults to "active" only! Use `comprehensiveConversationSearch` for keyword searches across all statuses.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | no | - | HelpScout query syntax (body, subject, email) |
| `status` | string | no | * | active, pending, closed, spam |
| `inboxId` | string | no | - | Scope to specific inbox (numeric ID as string) |
| `tag` | string | no | - | Filter by tag name |
| `createdAfter` | string | no | - | ISO8601 date |
| `createdBefore` | string | no | - | ISO8601 date |
| `sort` | string | no | "createdAt" | createdAt, updatedAt, number |
| `order` | string | no | "desc" | asc, desc |
| `limit` | number | no | 50 | Max results (1-100) |
| `cursor` | string | no | - | Pagination cursor |
| `fields` | array | no | - | Specific fields to return (partial response) |

*Status default: "active" when query/tag provided; all statuses otherwise

**When to use:**
- Listing recent tickets (no keyword search)
- Filtering by explicit status
- Time-based queries

**When NOT to use:**
- Keyword searches (use `comprehensiveConversationSearch`)
- Finding tickets across all statuses

**Example:**
```javascript
searchConversations({
  inboxId: "359402",
  status: "active",
  sort: "createdAt",
  order: "desc",
  limit: 20
})
```

---

## 4. comprehensiveConversationSearch

**Purpose:** Keyword search across all statuses. PREFERRED for content searches.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `searchTerms` | string[] | yes | - | Keywords to search (OR combined) |
| `inboxId` | string | no | - | Scope to specific inbox |
| `statuses` | string[] | no | ["active","pending","closed"] | Statuses to search |
| `searchIn` | string[] | no | ["both"] | body, subject, or both |
| `timeframeDays` | number | no | 60 | Days back to search (1-365) |
| `createdAfter` | string | no | - | Override timeframeDays |
| `createdBefore` | string | no | - | End date |
| `limitPerStatus` | number | no | 25 | Results per status (1-100) |
| `includeVariations` | boolean | no | true | Include term variations |

**Why this is preferred:**
- Searches all statuses by default
- Returns organized results grouped by status
- Executes parallel searches for performance

**Example:**
```javascript
comprehensiveConversationSearch({
  searchTerms: ["billing", "refund"],
  inboxId: "359402",
  timeframeDays: 30
})
```

---

## 5. advancedConversationSearch

**Purpose:** Complex filters with email domains, tags, and boolean logic.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `emailDomain` | string | no | - | Filter by domain (e.g., "company.com") |
| `customerEmail` | string | no | - | Exact email match |
| `contentTerms` | string[] | no | - | Search in body (OR combined) |
| `subjectTerms` | string[] | no | - | Search in subject (OR combined) |
| `tags` | string[] | no | - | Tag names (OR combined) |
| `inboxId` | string | no | - | Scope to inbox |
| `status` | string | no | - | active, pending, closed, spam |
| `createdAfter` | string | no | - | ISO8601 date |
| `createdBefore` | string | no | - | ISO8601 date |
| `limit` | number | no | 50 | Max results (1-100) |

**Use cases:**
- "Find all tickets from @acme.com"
- "Tickets with urgent AND billing tags"
- "Separate content and subject searches"

**Example:**
```javascript
advancedConversationSearch({
  emailDomain: "acme.com",
  tags: ["urgent"],
  status: "active"
})
```

---

## 6. structuredConversationFilter

**Purpose:** ID-based lookups and ticket number queries. Use AFTER discovery.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `conversationNumber` | number | no | - | Direct ticket # lookup |
| `assignedTo` | number | no | - | User ID (-1 for unassigned) |
| `customerIds` | number[] | no | - | Customer IDs (max 100) |
| `folderId` | number | no | - | Folder ID |
| `inboxId` | string | no | - | Inbox ID |
| `tag` | string | no | - | Tag name |
| `status` | string | no | "all" | active, pending, closed, spam, all |
| `sortBy` | string | no | "createdAt" | See options below |
| `sortOrder` | string | no | "desc" | asc, desc |
| `createdAfter` | string | no | - | ISO8601 date |
| `createdBefore` | string | no | - | ISO8601 date |
| `modifiedSince` | string | no | - | ISO8601 date |
| `limit` | number | no | 50 | Max results (1-100) |
| `cursor` | string | no | - | Pagination |

**Sort options:** createdAt, modifiedAt, number, waitingSince, customerName, customerEmail, mailboxId, status, subject

**Unique features:**
- Direct ticket number lookup
- waitingSince/customerName/customerEmail sorting (unavailable elsewhere)
- Requires at least one filter

**Example:**
```javascript
// Direct ticket lookup
structuredConversationFilter({ conversationNumber: 42839 })

// Customer history
structuredConversationFilter({
  customerIds: [12345],
  sortBy: "createdAt",
  sortOrder: "desc"
})
```

---

## 7. getConversationSummary

**Purpose:** Quick overview with first customer message + latest staff reply.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `conversationId` | string | yes | - | Conversation UUID |

**Returns:**
- Conversation metadata
- First customer message
- Latest staff reply

**Example:**
```javascript
getConversationSummary({ conversationId: "abc-123-def" })
```

---

## 8. getThreads

**Purpose:** Full message history for a conversation.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `conversationId` | string | yes | - | Conversation UUID |
| `limit` | number | no | 200 | Max threads (1-200) |
| `cursor` | string | no | - | Pagination |

**Returns:** All threads with metadata, source info, creator/customer details

**Example:**
```javascript
getThreads({ conversationId: "abc-123-def", limit: 200 })
```

---

## 9. getServerTime

**Purpose:** Get current server timestamp for time-relative calculations.

**Parameters:** None

**Returns:**
```javascript
{
  isoTime: "2024-01-15T10:30:00Z",
  unixTime: 1705315800
}
```

**Use case:** Reference for time-relative searches, debugging timestamp issues.
