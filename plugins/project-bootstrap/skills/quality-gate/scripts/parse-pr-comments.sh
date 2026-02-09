#!/usr/bin/env bash
# parse-pr-comments.sh - Extract and categorize PR comments from external tools and reviewers
# Usage: ./parse-pr-comments.sh <pr-number>

set -euo pipefail

PR_NUMBER="${1:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "Usage: $0 <pr-number>"
  echo "Example: $0 12"
  exit 1
fi

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "Fetching comments from PR #$PR_NUMBER..."

# Fetch PR comments as JSON
COMMENTS=$(gh pr view "$PR_NUMBER" --json comments 2>/dev/null || {
  echo "Error: Could not fetch PR #$PR_NUMBER"
  echo "Check that:"
  echo "  1. PR exists"
  echo "  2. You have access to the repository"
  echo "  3. gh CLI is authenticated (gh auth status)"
  exit 1
})

# Check if there are any comments
COMMENT_COUNT=$(echo "$COMMENTS" | jq '.comments | length')

if [ "$COMMENT_COUNT" -eq 0 ]; then
  echo "No comments found on PR #$PR_NUMBER"
  exit 0
fi

echo "Found $COMMENT_COUNT comment(s)"
echo ""

# External automated review tools to detect
EXTERNAL_TOOLS=(
  "devin-ai"
  "coderabbit"
  "renovate"
  "dependabot"
  "sonarcloud"
  "codecov"
  "github-advanced-security"
  "snyk-bot"
  "gitguardian"
)

# Categories
declare -A EXTERNAL_COMMENTS
declare -A MANUAL_COMMENTS
declare -A AGENT_COMMENTS

# Parse comments and categorize
while IFS= read -r comment; do
  AUTHOR=$(echo "$comment" | jq -r '.author.login')
  BODY=$(echo "$comment" | jq -r '.body')
  CREATED_AT=$(echo "$comment" | jq -r '.createdAt')

  # Check if it's an external tool
  IS_EXTERNAL=false
  for tool in "${EXTERNAL_TOOLS[@]}"; do
    if [[ "$AUTHOR" == *"$tool"* ]] || [[ "$AUTHOR" == "$tool" ]]; then
      EXTERNAL_COMMENTS["$AUTHOR"]="$BODY"
      IS_EXTERNAL=true
      break
    fi
  done

  # Check if it's from pr-review-toolkit agents
  if [[ "$BODY" == *"[code-reviewer]"* ]] || \
     [[ "$BODY" == *"[silent-failure-hunter]"* ]] || \
     [[ "$BODY" == *"[code-simplifier]"* ]] || \
     [[ "$BODY" == *"[comment-analyzer]"* ]] || \
     [[ "$BODY" == *"[pr-test-analyzer]"* ]] || \
     [[ "$BODY" == *"[type-design-analyzer]"* ]]; then
    AGENT_COMMENTS["$AUTHOR"]="$BODY"
  elif [ "$IS_EXTERNAL" = false ]; then
    # It's a manual comment
    MANUAL_COMMENTS["$AUTHOR"]="$BODY"
  fi
done < <(echo "$COMMENTS" | jq -c '.comments[]')

# Output categorized findings
echo "========================================="
echo "PR #$PR_NUMBER Comment Analysis"
echo "========================================="
echo ""

# External Tool Comments
if [ ${#EXTERNAL_COMMENTS[@]} -gt 0 ]; then
  echo -e "${BLUE}📡 External Automated Tools (${#EXTERNAL_COMMENTS[@]} tool(s))${NC}"
  echo ""

  for author in "${!EXTERNAL_COMMENTS[@]}"; do
    echo -e "  ${GREEN}[$author]${NC}"

    # Count findings by severity
    BODY="${EXTERNAL_COMMENTS[$author]}"
    CRITICAL_COUNT=$(echo "$BODY" | grep -c "🔴\|CRITICAL\|BLOCKER" || true)
    HIGH_COUNT=$(echo "$BODY" | grep -c "🟠\|⚠️\|HIGH\|MAJOR" || true)
    MEDIUM_COUNT=$(echo "$BODY" | grep -c "🟡\|MEDIUM\|MODERATE" || true)
    LOW_COUNT=$(echo "$BODY" | grep -c "🔵\|💡\|LOW\|INFO" || true)
    POSITIVE_COUNT=$(echo "$BODY" | grep -c "✅\|POSITIVE\|LGTM" || true)

    [ "$CRITICAL_COUNT" -gt 0 ] && echo -e "    🔴 Critical: $CRITICAL_COUNT"
    [ "$HIGH_COUNT" -gt 0 ] && echo -e "    🟠 High: $HIGH_COUNT"
    [ "$MEDIUM_COUNT" -gt 0 ] && echo -e "    🟡 Medium: $MEDIUM_COUNT"
    [ "$LOW_COUNT" -gt 0 ] && echo -e "    🔵 Low: $LOW_COUNT"
    [ "$POSITIVE_COUNT" -gt 0 ] && echo -e "    ✅ Positive: $POSITIVE_COUNT"

    echo ""
  done
fi

# Agent Comments
if [ ${#AGENT_COMMENTS[@]} -gt 0 ]; then
  echo -e "${YELLOW}🤖 pr-review-toolkit Agents (${#AGENT_COMMENTS[@]} comment(s))${NC}"
  echo ""

  for author in "${!AGENT_COMMENTS[@]}"; do
    echo -e "  ${GREEN}[$author]${NC}"

    # Parse agent findings
    BODY="${AGENT_COMMENTS[$author]}"

    # Count by agent type
    for agent in "code-reviewer" "silent-failure-hunter" "code-simplifier" "comment-analyzer" "pr-test-analyzer" "type-design-analyzer"; do
      if echo "$BODY" | grep -q "\[$agent\]"; then
        COUNT=$(echo "$BODY" | grep -c "\[$agent\]" || true)
        echo "    [$agent]: $COUNT finding(s)"
      fi
    done

    echo ""
  done
fi

# Manual Reviewer Comments
if [ ${#MANUAL_COMMENTS[@]} -gt 0 ]; then
  echo -e "${GREEN}👤 Manual Reviewers (${#MANUAL_COMMENTS[@]} reviewer(s))${NC}"
  echo ""

  for author in "${!MANUAL_COMMENTS[@]}"; do
    echo -e "  ${GREEN}[$author]${NC}"

    # Show snippet of comment
    BODY="${MANUAL_COMMENTS[$author]}"
    SNIPPET=$(echo "$BODY" | head -n 3 | tr '\n' ' ' | cut -c1-80)
    echo "    ${SNIPPET}..."
    echo ""
  done
fi

# Summary
echo "========================================="
echo "Summary"
echo "========================================="
echo ""
echo "Total Comments: $COMMENT_COUNT"
echo "  - External Tools: ${#EXTERNAL_COMMENTS[@]}"
echo "  - Agent Reviews: ${#AGENT_COMMENTS[@]}"
echo "  - Manual Reviewers: ${#MANUAL_COMMENTS[@]}"
echo ""

# Export for downstream processing
FINDINGS_JSON=$(cat <<EOF
{
  "pr_number": $PR_NUMBER,
  "total_comments": $COMMENT_COUNT,
  "external_tools": ${#EXTERNAL_COMMENTS[@]},
  "agent_reviews": ${#AGENT_COMMENTS[@]},
  "manual_reviews": ${#MANUAL_COMMENTS[@]},
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

echo "$FINDINGS_JSON" > /tmp/pr-${PR_NUMBER}-findings.json
echo "Findings exported to: /tmp/pr-${PR_NUMBER}-findings.json"
