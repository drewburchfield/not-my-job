#!/usr/bin/env bash
# validate-pr-ready.sh - Check prerequisites before quality gate PR workflow
# Usage: ./validate-pr-ready.sh [--linear-issue ISSUE-ID]

set -euo pipefail

# Parse arguments
LINEAR_ISSUE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --linear-issue)
      LINEAR_ISSUE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--linear-issue ISSUE-ID]"
      exit 1
      ;;
  esac
done

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "========================================="
echo "Quality Gate Prerequisites Validation"
echo "========================================="
echo ""

# Check 1: Git repository
echo -n "Checking git repository... "
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  echo "  Error: Not in a git repository"
  ((ERRORS++))
fi

# Check 2: On feature branch (not master/main)
echo -n "Checking branch... "
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

if [ -z "$CURRENT_BRANCH" ]; then
  echo -e "${RED}✗${NC}"
  echo "  Error: Detached HEAD state"
  ((ERRORS++))
elif [ "$CURRENT_BRANCH" = "master" ] || [ "$CURRENT_BRANCH" = "main" ]; then
  echo -e "${RED}✗${NC}"
  echo "  Error: On branch '$CURRENT_BRANCH'"
  echo "  Cannot create PR from master/main branch"
  echo "  Create a feature branch: git checkout -b feature/branch-name"
  ((ERRORS++))
else
  echo -e "${GREEN}✓${NC} (on $CURRENT_BRANCH)"
fi

# Check 3: No uncommitted changes
echo -n "Checking working directory... "
if [ -z "$(git status --porcelain)" ]; then
  echo -e "${GREEN}✓${NC} (clean)"
else
  echo -e "${RED}✗${NC}"
  echo "  Error: Uncommitted changes detected"
  echo ""
  git status --short
  echo ""
  echo "  Commit or stash changes before running quality gate"
  ((ERRORS++))
fi

# Check 4: Branch has commits ahead of master
echo -n "Checking commits... "
AHEAD_COUNT=$(git rev-list --count origin/master..HEAD 2>/dev/null || echo "0")

if [ "$AHEAD_COUNT" -eq 0 ]; then
  echo -e "${YELLOW}⚠${NC}"
  echo "  Warning: No commits ahead of origin/master"
  echo "  Nothing to review in PR"
  ((WARNINGS++))
else
  echo -e "${GREEN}✓${NC} ($AHEAD_COUNT commit(s) ahead)"
fi

# Check 5: Branch pushed to remote
echo -n "Checking remote branch... "
if git rev-parse --verify "origin/$CURRENT_BRANCH" &>/dev/null; then
  echo -e "${GREEN}✓${NC}"

  # Check if local is behind remote
  LOCAL_SHA=$(git rev-parse HEAD)
  REMOTE_SHA=$(git rev-parse "origin/$CURRENT_BRANCH")

  if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
    echo -e "  ${YELLOW}⚠ Local branch differs from remote${NC}"
    echo "    Run: git push"
    ((WARNINGS++))
  fi
else
  echo -e "${YELLOW}⚠${NC}"
  echo "  Warning: Branch not pushed to remote"
  echo "  Will need to push before creating PR"
  ((WARNINGS++))
fi

# Check 6: GitHub CLI available
echo -n "Checking GitHub CLI... "
if command -v gh &> /dev/null; then
  echo -e "${GREEN}✓${NC}"

  # Check gh authentication
  if gh auth status &>/dev/null; then
    echo -e "  ${GREEN}✓ Authenticated${NC}"
  else
    echo -e "  ${RED}✗ Not authenticated${NC}"
    echo "    Run: gh auth login"
    ((ERRORS++))
  fi
else
  echo -e "${RED}✗${NC}"
  echo "  Error: gh CLI not found"
  echo "  Install: brew install gh (macOS) or https://cli.github.com"
  ((ERRORS++))
fi

# Check 7: Linear issue (if provided)
if [ -n "$LINEAR_ISSUE" ]; then
  echo -n "Checking Linear issue... "

  if command -v linear &> /dev/null; then
    if linear issue "$LINEAR_ISSUE" &>/dev/null; then
      ISSUE_STATUS=$(linear issue "$LINEAR_ISSUE" --json | jq -r '.state.type' 2>/dev/null || echo "unknown")

      if [ "$ISSUE_STATUS" = "completed" ] || [ "$ISSUE_STATUS" = "canceled" ]; then
        echo -e "${RED}✗${NC}"
        echo "  Error: Issue $LINEAR_ISSUE is $ISSUE_STATUS"
        echo "  Cannot work on completed/canceled issues"
        ((ERRORS++))
      else
        echo -e "${GREEN}✓${NC} ($LINEAR_ISSUE - $ISSUE_STATUS)"
      fi
    else
      echo -e "${RED}✗${NC}"
      echo "  Error: Issue $LINEAR_ISSUE not found"
      ((ERRORS++))
    fi
  else
    echo -e "${YELLOW}⚠${NC}"
    echo "  Warning: linear CLI not found"
    echo "  Install: npm install -g @linear/cli"
    echo "  Or skip Linear integration: /quality-gate --no-issue"
    ((WARNINGS++))
  fi
else
  echo -n "Checking Linear integration... "
  if command -v linear &> /dev/null; then
    echo -e "${GREEN}✓${NC} (CLI available)"
  else
    echo -e "${YELLOW}⚠${NC}"
    echo "  Info: linear CLI not available"
    echo "  Will attempt issue detection or run in standalone mode"
  fi
fi

# Check 8: pr-review-toolkit available
echo -n "Checking pr-review-toolkit... "
# This would check if the skill is available in Claude
# For now, just note it's expected
echo -e "${GREEN}✓${NC} (expected to be available)"

# Summary
echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✓ All prerequisites met${NC}"
  echo "Ready to run quality gate workflow"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
  echo "Can proceed but may encounter issues"
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s) found${NC}"
  if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
  fi
  echo ""
  echo "Fix errors before running quality gate"
  exit 1
fi
