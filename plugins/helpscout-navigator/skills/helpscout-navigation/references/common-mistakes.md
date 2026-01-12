# Common HelpScout MCP Mistakes

Detailed anti-patterns with explanations and fixes.

---

## Mistake 1: Searching Without Inbox Lookup

**What happens:**
```javascript
// User says: "Search the support inbox for billing"
// WRONG:
searchConversations({ query: "billing", inboxId: "support" })
// Error: "support" is not a valid inbox ID
```

**Why it fails:** The API requires inbox UUIDs, not names. "support" is a name, not an ID.

**Correct approach:**
```javascript
// Step 1: Look up inbox ID
searchInboxes({ query: "support" })
// Returns: { id: "abc123", name: "Support" }

// Step 2: Use the ID
searchConversations({ query: "billing", inboxId: "abc123" })
```

---

## Mistake 2: Using searchConversations for Keyword Search

**What happens:**
```javascript
// User says: "Find tickets about refunds"
// WRONG:
searchConversations({ query: "refund" })
// Only returns ACTIVE tickets - misses 80%+ of closed/pending tickets
```

**Why it fails:** `searchConversations` defaults to `status: "active"`. Most tickets are closed.

**Correct approach:**
```javascript
// Use comprehensive search - searches all statuses by default
comprehensiveConversationSearch({ searchTerms: ["refund"] })
```

---

## Mistake 3: Assuming searchConversations Returns All Statuses

**What happens:**
```javascript
// User says: "How many tickets do we have?"
// WRONG assumption:
searchConversations({})
// Only counts active tickets!
```

**Why it fails:** Without explicit `status`, only "active" tickets are returned.

**Correct approach:**
```javascript
// Option 1: Explicit statuses
searchConversations({ status: "closed" })
searchConversations({ status: "pending" })
searchConversations({ status: "active" })

// Option 2: Use comprehensive search
comprehensiveConversationSearch({
  searchTerms: ["*"],
  statuses: ["active", "pending", "closed"]
})
```

---

## Mistake 4: Using Inbox Names Instead of UUIDs

**What happens:**
```javascript
// WRONG:
searchConversations({ inboxId: "Support" })
searchConversations({ inboxId: "sales@company.com" })
// Both fail - not valid UUIDs
```

**Why it fails:** Inbox IDs are UUIDs like `"abc123-def456"`, not names or emails.

**Correct approach:**
```javascript
// Always look up first
const inboxes = searchInboxes({ query: "support" });
const inboxId = inboxes[0].id; // "abc123-def456"
searchConversations({ inboxId: inboxId })
```

---

## Mistake 5: Using structuredConversationFilter as First Search

**What happens:**
```javascript
// User says: "Find tickets assigned to John"
// WRONG:
structuredConversationFilter({ assignedTo: "John" })
// Error: assignedTo requires a user ID (number), not a name
```

**Why it fails:** `structuredConversationFilter` works with IDs from previous searches.

**Correct approach:**
```javascript
// Step 1: Find John's user ID (from a previous search or user lookup)
// Step 2: Then filter
structuredConversationFilter({ assignedTo: 12345 })
```

**Exception:** Direct ticket number lookup works without prior search:
```javascript
structuredConversationFilter({ conversationNumber: 42839 })
```

---

## Mistake 6: Not Including Search Term Variations

**What happens:**
```javascript
// User says: "Find billing issues"
// Suboptimal:
comprehensiveConversationSearch({ searchTerms: ["billing"] })
// Misses "bill", "billed", "invoice", etc.
```

**Better approach:**
```javascript
comprehensiveConversationSearch({
  searchTerms: ["billing", "invoice", "payment"],
  includeVariations: true
})
```

---

## Mistake 7: Ignoring Pagination for Large Result Sets

**What happens:**
```javascript
// User says: "Get all tickets from last month"
// WRONG:
searchConversations({ createdAfter: "2024-01-01" })
// Only returns first 50 results (default limit)
```

**Why it fails:** Default limit is 50. Large date ranges may have hundreds of tickets.

**Correct approach:**
```javascript
// Check for cursor in response
let cursor = null;
do {
  const result = searchConversations({
    createdAfter: "2024-01-01",
    cursor: cursor,
    limit: 100
  });
  // Process result.conversations
  cursor = result.nextCursor;
} while (cursor);
```

---

## Mistake 8: Not Specifying Timeframe

**What happens:**
```javascript
// User says: "Find urgent tickets"
// Suboptimal:
comprehensiveConversationSearch({ searchTerms: ["urgent"] })
// Searches 60 days by default - might be too much or too little
```

**Better approach:**
```javascript
// Be explicit about timeframe
comprehensiveConversationSearch({
  searchTerms: ["urgent"],
  timeframeDays: 7  // Last week
})

// Or use specific dates
comprehensiveConversationSearch({
  searchTerms: ["urgent"],
  createdAfter: "2024-01-15T00:00:00Z"
})
```

---

## Mistake 9: Missing Content in Thread Retrieval

**What happens:**
```javascript
getConversationSummary({ conversationId: "abc123" })
// Returns: { body: "[Content hidden - set REDACT_MESSAGE_CONTENT=false to view]" }
```

**Why it fails:** The MCP server has content redaction enabled.

**Fix:** User needs to set environment variable `REDACT_MESSAGE_CONTENT=false` when starting the MCP.

---

## Quick Checklist

Before any HelpScout operation, verify:

| Check | Action |
|-------|--------|
| User mentioned inbox name? | Call `searchInboxes` first |
| Searching by keywords? | Use `comprehensiveConversationSearch` |
| Need closed/pending tickets? | Don't use bare `searchConversations` |
| Using inbox ID in API call? | Ensure it's a UUID, not name |
| Using `structuredConversationFilter`? | Have IDs from prior search (except ticket #) |
| Large result set expected? | Handle pagination with cursor |
| Need specific timeframe? | Set `timeframeDays` or date params |
