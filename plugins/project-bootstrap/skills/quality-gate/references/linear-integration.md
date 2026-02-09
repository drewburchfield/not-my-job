# Linear Integration Reference

Patterns and commands for integrating Linear issue tracking with the quality-gate workflow.

## Linear CLI Commands

### Get Issue Details

```bash
# Fetch issue by ID
linear issue NAS-577

# Output shows:
# - Title
# - Description
# - Status (Backlog, Todo, In Progress, Done, etc.)
# - Assignee
# - Project/Milestone
# - Labels
```

### Update Issue Status

```bash
# Mark issue as Done after merge
linear issue update NAS-577 --status "Done"

# Other common statuses:
linear issue update NAS-577 --status "In Progress"
linear issue update NAS-577 --status "In Review"
```

### Add Issue Comment

```bash
# Link PR to issue
linear issue comment NAS-577 "Merged in PR #12: https://github.com/user/repo/pull/12"

# Add status updates
linear issue comment NAS-577 "Quality gate passed. All agent reviews clean."
```

### List Issues

```bash
# Find issues by branch name
linear issue list --filter "gitBranchName contains 'feature/nas-577'"

# Find issues by assignee
linear issue list --filter "assignee.email = 'user@example.com'" --filter "status.type = 'started'"
```

## Linear MCP Alternative

If using Linear MCP server instead of CLI:

```javascript
// Use MCP tools via Claude
// Available tools:
// - linear_get_issue
// - linear_update_issue
// - linear_add_comment
// - linear_search_issues

// MCP handles authentication automatically
// Prefer MCP when available for better integration
```

## Issue Detection Patterns

### From Branch Name

Extract issue number from common branch naming patterns:

```bash
# Pattern: feature/nas-577-description
BRANCH=$(git branch --show-current)
ISSUE=$(echo "$BRANCH" | grep -oiE "nas-?[0-9]+" | head -1 | tr '[:lower:]' '[:upper:]')

# Handles:
# - feature/nas-577-description → NAS-577
# - drewburchfield/nas-577-fix → NAS-577
# - nas-577-quick-fix → NAS-577
# - fix/NAS-577 → NAS-577
```

### From Commit Messages

Extract issue references from recent commits:

```bash
# Look for "Fixes NAS-XXX" or "Closes NAS-XXX"
git log -10 --pretty=%s | grep -oiE "(fixes|closes|refs) nas-?[0-9]+" | head -1
```

### From Linear API

Query Linear for issues linked to current branch:

```bash
BRANCH=$(git branch --show-current)
linear issue list --filter "gitBranchName contains '$BRANCH'" --limit 1
```

## Validation

### Check Issue Exists and is Valid

```bash
# Get issue and check status
ISSUE_STATUS=$(linear issue NAS-577 --json | jq -r '.state.type')

# Valid states for quality gate:
# - "started" (In Progress) ✓
# - "unstarted" (Todo) ✓
# - "completed" (Done) ✗ (can't reopen completed issues)
# - "canceled" (Canceled) ✗

if [ "$ISSUE_STATUS" = "completed" ] || [ "$ISSUE_STATUS" = "canceled" ]; then
  echo "❌ Issue $ISSUE is already $ISSUE_STATUS"
  exit 1
fi
```

## Standalone Mode (No Linear Issue)

When no Linear issue is detected or `--no-issue` flag is used:

- Skip issue validation
- Skip status updates
- Skip issue comments
- Full PR workflow still runs (agents, Devin, merge)
- Use for: hotfixes, docs, experiments, third-party contributions

## Error Handling

### Issue Not Found

```bash
# Linear CLI returns exit code 1
if ! linear issue NAS-577 &>/dev/null; then
  echo "❌ Issue NAS-577 not found in Linear"
  echo "Options:"
  echo "  1. Check issue number"
  echo "  2. Run without issue: /quality-gate --no-issue"
  exit 1
fi
```

### Status Update Fails

```bash
# Continue with merge, manual Linear update
linear issue update NAS-577 --status "Done" || {
  echo "⚠️ Failed to update Linear status automatically"
  echo "Please update manually: https://linear.app/nashburch/issue/NAS-577"
}
```

### API Rate Limits

```bash
# Linear API is rate-limited
# If rate limited, wait and retry once
linear issue NAS-577 || {
  echo "⚠️ Linear API rate limit. Retrying in 5s..."
  sleep 5
  linear issue NAS-577
}
```

## Best Practices

1. **Always validate issue before starting** - Prevents work on closed/canceled issues
2. **Link PR in issue comment** - Maintains traceability
3. **Update status only after successful merge** - Don't mark Done prematurely
4. **Use standalone mode for quick fixes** - Don't force Linear tracking on everything
5. **Gracefully handle Linear failures** - Don't block merge if Linear API is down

## Authentication

### Linear CLI

```bash
# Set API key
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"

# Or configure globally
linear auth login
```

### Linear MCP

Configured in MCP settings. No manual auth needed in workflow.
