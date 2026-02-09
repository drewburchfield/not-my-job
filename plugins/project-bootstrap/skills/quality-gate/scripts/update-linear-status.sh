#!/usr/bin/env bash
# update-linear-status.sh - Update Linear issue status
# Usage: ./update-linear-status.sh <issue-id> <status> [comment]

set -euo pipefail

ISSUE_ID="${1:-}"
STATUS="${2:-}"
COMMENT="${3:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$ISSUE_ID" ] || [ -z "$STATUS" ]; then
  echo "Usage: $0 <issue-id> <status> [comment]"
  echo ""
  echo "Arguments:"
  echo "  issue-id  Linear issue ID (e.g., NAS-577)"
  echo "  status    Target status (e.g., Done, In Progress, Todo)"
  echo "  comment   Optional comment to add (e.g., 'Merged in PR #12')"
  echo ""
  echo "Examples:"
  echo "  $0 NAS-577 Done 'Merged in PR #12'"
  echo "  $0 NAS-577 'In Progress'"
  exit 1
fi

# Check if linear CLI is available
if ! command -v linear &> /dev/null; then
  echo -e "${RED}Error: linear CLI not found${NC}"
  echo ""
  echo "Install with:"
  echo "  npm install -g @linear/cli"
  echo ""
  echo "Or configure authentication:"
  echo "  export LINEAR_API_KEY='lin_api_xxxxx'"
  echo "  linear auth login"
  exit 1
fi

echo "Updating Linear issue $ISSUE_ID..."

# Verify issue exists
if ! linear issue "$ISSUE_ID" &>/dev/null; then
  echo -e "${RED}Error: Issue $ISSUE_ID not found${NC}"
  echo ""
  echo "Possible issues:"
  echo "  - Issue ID is incorrect"
  echo "  - You don't have access to this issue"
  echo "  - Authentication failed (run: linear auth status)"
  exit 1
fi

# Get current status
CURRENT_STATUS=$(linear issue "$ISSUE_ID" --json | jq -r '.state.name' 2>/dev/null || echo "Unknown")
echo "Current status: $CURRENT_STATUS"

# Update status
echo "Setting status to: $STATUS"

if linear issue update "$ISSUE_ID" --status "$STATUS" 2>&1 | tee /tmp/linear-update.log; then
  echo -e "${GREEN}✓ Status updated successfully${NC}"
else
  ERROR_MSG=$(cat /tmp/linear-update.log)
  echo -e "${RED}✗ Failed to update status${NC}"
  echo ""
  echo "Error details:"
  echo "$ERROR_MSG"
  echo ""

  # Common error handling
  if echo "$ERROR_MSG" | grep -q "Invalid status"; then
    echo "Valid statuses for your workspace (check with: linear workflow list):"
    echo "  - Backlog"
    echo "  - Todo"
    echo "  - In Progress"
    echo "  - In Review"
    echo "  - Done"
    echo "  - Canceled"
  elif echo "$ERROR_MSG" | grep -q "rate limit"; then
    echo "Linear API rate limit reached. Retrying in 5 seconds..."
    sleep 5
    linear issue update "$ISSUE_ID" --status "$STATUS"
  fi

  exit 1
fi

# Add comment if provided
if [ -n "$COMMENT" ]; then
  echo "Adding comment..."

  if linear issue comment "$ISSUE_ID" "$COMMENT" 2>&1 | tee /tmp/linear-comment.log; then
    echo -e "${GREEN}✓ Comment added successfully${NC}"
  else
    echo -e "${YELLOW}⚠ Failed to add comment (status was updated)${NC}"
    echo "Error: $(cat /tmp/linear-comment.log)"
    echo ""
    echo "You can add the comment manually:"
    echo "  linear issue comment $ISSUE_ID '$COMMENT'"
  fi
fi

# Show updated issue
echo ""
echo "Updated issue details:"
linear issue "$ISSUE_ID" | head -15

# Export result
RESULT_JSON=$(cat <<EOF
{
  "issue_id": "$ISSUE_ID",
  "previous_status": "$CURRENT_STATUS",
  "new_status": "$STATUS",
  "comment_added": $([ -n "$COMMENT" ] && echo "true" || echo "false"),
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "success": true
}
EOF
)

echo "$RESULT_JSON" > /tmp/linear-update-result.json
echo ""
echo -e "${GREEN}✓ Complete${NC}"
echo "Result exported to: /tmp/linear-update-result.json"
