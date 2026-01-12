# HelpScout Tool Decision Tree

Expanded decision logic for complex search scenarios.

---

## Scenario 1: Multi-Inbox Search

**User:** "Search all inboxes for tickets about API issues"

**Approach:**
```javascript
// Option A: Search without inbox filter (searches all)
comprehensiveConversationSearch({
  searchTerms: ["API", "api error", "integration"]
})

// Option B: Get all inboxes and search each
const inboxes = listAllInboxes();
for (const inbox of inboxes) {
  comprehensiveConversationSearch({
    searchTerms: ["API"],
    inboxId: inbox.id
  });
}
```

**When to use Option B:**
- Need results grouped by inbox
- Different search terms per inbox
- Reporting on inbox-specific metrics

---

## Scenario 2: Date-Range Filtering

**User:** "Find tickets from Q4 2023"

**Approach:**
```javascript
comprehensiveConversationSearch({
  searchTerms: ["*"],  // Or specific terms
  createdAfter: "2023-10-01T00:00:00Z",
  createdBefore: "2024-01-01T00:00:00Z"
})
```

**For time-relative queries:**
```javascript
// "Last 7 days"
const now = getServerTime();
comprehensiveConversationSearch({
  searchTerms: ["*"],
  timeframeDays: 7
})

// "Last month"
comprehensiveConversationSearch({
  searchTerms: ["*"],
  timeframeDays: 30
})
```

---

## Scenario 3: Customer History

**User:** "Show all tickets from customer@example.com"

**Approach:**
```javascript
// Step 1: Find customer using advanced search
const results = advancedConversationSearch({
  customerEmail: "customer@example.com"
});

// Step 2: Get customer ID from results
const customerId = results[0].customer.id;

// Step 3: Get full history with structuredConversationFilter
structuredConversationFilter({
  customerIds: [customerId],
  sortBy: "createdAt",
  sortOrder: "desc",
  status: "all"
})
```

**For domain-wide search:**
```javascript
advancedConversationSearch({
  emailDomain: "example.com"
})
```

---

## Scenario 4: Assignee-Based Filtering

**User:** "Show John's open tickets"

**Approach:**
```javascript
// Step 1: Need John's user ID
// This typically comes from user list or prior conversation data

// Step 2: Filter by assignee
structuredConversationFilter({
  assignedTo: 12345,  // John's user ID
  status: "active",
  sortBy: "waitingSince",  // Unique to this tool
  sortOrder: "asc"  // Longest waiting first
})
```

**For unassigned tickets:**
```javascript
structuredConversationFilter({
  assignedTo: -1,  // Special value for unassigned
  status: "active"
})
```

---

## Scenario 5: Tag-Based Search

**User:** "Find all tickets tagged 'urgent' or 'escalated'"

**Approach:**
```javascript
// Option A: Using advancedConversationSearch (OR logic)
advancedConversationSearch({
  tags: ["urgent", "escalated"]  // OR combined
})

// Option B: Multiple searches for AND logic
const urgentResults = advancedConversationSearch({
  tags: ["urgent"]
});
const escalatedResults = advancedConversationSearch({
  tags: ["escalated"]
});
// Combine results
```

**For tag + content search:**
```javascript
advancedConversationSearch({
  tags: ["urgent"],
  contentTerms: ["billing", "payment"]
})
```

---

## Scenario 6: Folder-Based Queries

**User:** "Show tickets in the 'Needs Follow-up' folder"

**Approach:**
```javascript
// Note: Folder IDs are visible in HelpScout UI URL
// e.g., helpscout.net/mailbox/12345/folder/67890
structuredConversationFilter({
  folderId: 67890,
  sortBy: "modifiedAt",
  sortOrder: "desc"
})
```

---

## Scenario 7: Conversation Deep Dive

**User:** "Tell me everything about ticket #42839"

**Approach:**
```javascript
// Step 1: Get conversation by number
const conv = structuredConversationFilter({
  conversationNumber: 42839
});
const conversationId = conv[0].id;

// Step 2: Get summary (first + latest messages)
getConversationSummary({ conversationId });

// Step 3: Get full thread if needed
getThreads({ conversationId, limit: 200 });
```

---

## Scenario 8: Status Transitions

**User:** "Find recently closed tickets that were open for more than a week"

**Approach:**
```javascript
// Step 1: Get recently closed tickets
const closed = searchConversations({
  status: "closed",
  sort: "updatedAt",  // Recently closed = recently updated
  order: "desc",
  limit: 100
});

// Step 2: Filter by duration (in your code)
// Check createdAt vs closedAt difference
```

---

## Decision Tree Summary

```
START
  │
  ├─ Do you know the exact ticket number?
  │   └─ YES → structuredConversationFilter({ conversationNumber: X })
  │
  ├─ Is the user asking about a specific inbox?
  │   └─ YES → searchInboxes() FIRST, then continue
  │
  ├─ Are you searching by keywords/content?
  │   └─ YES → comprehensiveConversationSearch()
  │
  ├─ Are you filtering by email domain or complex tags?
  │   └─ YES → advancedConversationSearch()
  │
  ├─ Are you filtering by assignee, customer ID, or folder?
  │   └─ YES → structuredConversationFilter() (need IDs first)
  │
  ├─ Just listing recent tickets by status/time?
  │   └─ YES → searchConversations() (with explicit status!)
  │
  └─ Need full conversation details?
      ├─ Quick overview → getConversationSummary()
      └─ Full thread → getThreads()
```

---

## Performance Tips

1. **Start narrow, expand if needed**
   - Begin with specific inbox/timeframe
   - Widen search only if results are insufficient

2. **Use pagination for large results**
   - Always check for `nextCursor` in responses
   - Process in batches for memory efficiency

3. **Leverage includeVariations**
   - Helps catch related terms automatically
   - Reduces need for manual term expansion

4. **Cache inbox IDs**
   - Inbox IDs rarely change
   - Store after first lookup to avoid repeated calls
