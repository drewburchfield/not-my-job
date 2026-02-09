# GitHub CLI Integration Reference

Commands and patterns for GitHub CLI (`gh`) operations in the quality-gate workflow.

## Prerequisites

### Authentication

```bash
# Login to GitHub
gh auth login

# Verify authentication
gh auth status

# Should show:
# ✓ Logged in to github.com as username
# ✓ Token: gho_xxxxxxxxxxxx
```

### Repository Context

```bash
# Verify in git repository
git remote -v

# Should show origin pointing to GitHub
# origin  https://github.com/user/repo.git (fetch)
# origin  https://github.com/user/repo.git (push)
```

## PR Creation

### Basic PR Creation

```bash
# Create PR from current branch to master
gh pr create \
  --title "$(git log -1 --pretty=%s)" \
  --body "Description of changes" \
  --base master \
  --head "$(git branch --show-current)"
```

### PR with Template Body

```bash
# Create PR with structured description
gh pr create \
  --title "Replace quality-review with quality-gate skill" \
  --body "$(cat <<'EOF'
## Summary
Brief description of what this PR does.

### Changes
- Change 1
- Change 2
- Change 3

### Linear Issue
Fixes https://linear.app/team/issue/NAS-577

### Testing
How this was tested and validated.

### Review Focus
What reviewers should pay attention to.
EOF
)" \
  --base master \
  --head "feature/quality-gate-implementation"
```

### Capture PR Number and URL

```bash
# Create PR and capture URL
PR_URL=$(gh pr create --title "..." --body "..." --base master --head "$(git branch --show-current)")

# Extract PR number from URL
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')

echo "Created PR #$PR_NUMBER: $PR_URL"
```

## PR Viewing

### Get PR Details

```bash
# View PR in terminal
gh pr view 12

# View PR in browser
gh pr view 12 --web
```

### Get PR Status

```bash
# Check PR checks/status
gh pr checks 12

# Output shows:
# ✓ CI / Build (main) (push)
# ✓ lint
# ✗ test (failed)
```

### Get PR Comments

```bash
# Fetch all comments as JSON
gh pr view 12 --json comments

# Parse comments with jq
gh pr view 12 --json comments | jq -r '.comments[] | "[\(.author.login)] \(.body)"'

# Filter comments by author (e.g., Devin.ai)
gh pr view 12 --json comments | jq -r '.comments[] | select(.author.login == "devin-ai") | .body'

# Get comment count
gh pr view 12 --json comments | jq '.comments | length'
```

### Get PR Diff

```bash
# View diff in terminal
gh pr diff 12

# Get specific file diff
gh pr diff 12 -- path/to/file.ts

# Get diff stats
gh pr diff 12 --stat
```

## PR Commenting

### Add Comment

```bash
# Add comment to PR
gh pr comment 12 --body "LGTM! Approving."

# Add comment with mention
gh pr comment 12 --body "@username Please review the error handling"

# Add multiline comment
gh pr comment 12 --body "$(cat <<'EOF'
## Review Findings

Found 3 issues:
1. Issue one
2. Issue two
3. Issue three
EOF
)"
```

## PR Merging

### Squash and Merge (Default)

```bash
# Squash commits into one and merge
gh pr merge 12 --squash --delete-branch

# With custom commit message
gh pr merge 12 --squash --delete-branch --subject "Add quality-gate skill" --body "Complete implementation"
```

### Rebase and Merge

```bash
# Rebase onto base branch and merge
gh pr merge 12 --rebase --delete-branch

# Use for clean linear history
```

### Merge Commit

```bash
# Create merge commit (preserves all commits)
gh pr merge 12 --merge --delete-branch

# Use for feature branches with meaningful commit history
```

### Auto-merge (when checks pass)

```bash
# Enable auto-merge
gh pr merge 12 --squash --auto

# PR will merge automatically when:
# - All checks pass
# - Required reviews approved
# - No merge conflicts
```

## PR Review Operations

### Request Review

```bash
# Request review from user
gh pr review 12 --request @username

# Request review from team
gh pr review 12 --request @org/team-name
```

### Approve PR

```bash
# Approve with comment
gh pr review 12 --approve --body "Looks good!"

# Approve without comment
gh pr review 12 --approve
```

### Request Changes

```bash
# Request changes with comment
gh pr review 12 --request-changes --body "Please address the error handling issues"
```

## Error Handling

### PR Already Exists

```bash
# Check if PR exists for current branch
EXISTING_PR=$(gh pr list --head "$(git branch --show-current)" --json number --jq '.[0].number')

if [ -n "$EXISTING_PR" ]; then
  echo "PR already exists: #$EXISTING_PR"
  PR_NUMBER=$EXISTING_PR
else
  # Create new PR
  gh pr create ...
fi
```

### Merge Conflicts

```bash
# Check for merge conflicts
gh pr view 12 --json mergeable | jq -r '.mergeable'

# Returns: "MERGEABLE", "CONFLICTING", or "UNKNOWN"

if [ "$MERGEABLE" = "CONFLICTING" ]; then
  echo "❌ PR has merge conflicts. Resolve locally:"
  echo "  git checkout feature-branch"
  echo "  git merge master"
  echo "  # Resolve conflicts"
  echo "  git push"
  exit 1
fi
```

### Failed Checks

```bash
# Check if all checks passed
gh pr checks 12 --json state --jq '.[] | select(.state != "SUCCESS") | .name'

# If any checks failed, list them
FAILED_CHECKS=$(gh pr checks 12 --json state --jq '.[] | select(.state == "FAILURE") | .name')

if [ -n "$FAILED_CHECKS" ]; then
  echo "❌ Failed checks:"
  echo "$FAILED_CHECKS"
  exit 1
fi
```

### API Rate Limits

```bash
# Check rate limit status
gh api rate_limit

# If rate limited, wait
gh pr view 12 || {
  echo "⚠️ GitHub API rate limit. Retrying in 60s..."
  sleep 60
  gh pr view 12
}
```

## Advanced Patterns

### Parse PR Comments for Review Findings

```bash
# Get all comments, filter for review tools
gh pr view 12 --json comments | jq -r '
  .comments[] |
  select(.author.login | test("devin-ai|coderabbit|renovate")) |
  "[\(.author.login)] \(.createdAt)\n\(.body)\n---"
'
```

### Update PR After Remediation

```bash
# Make fixes
git add -A
git commit -m "Address PR review findings"
git push

# Comment on PR
gh pr comment 12 --body "✅ Addressed all review findings. Re-running checks."
```

### Close PR Without Merging

```bash
# Close PR (e.g., abandoned work)
gh pr close 12 --comment "Closing in favor of alternate approach"

# Delete branch
git branch -d feature-branch
git push origin --delete feature-branch
```

## Best Practices

1. **Always capture PR number** - Store in variable for subsequent operations
2. **Use structured PR bodies** - Include Linear issue, testing notes, review focus
3. **Wait for external tools** - Give automated reviewers time to comment
4. **Check for conflicts before merge** - Avoid failed merge attempts
5. **Delete branch after merge** - Keep repository clean
6. **Use --squash for feature branches** - Clean commit history in main
7. **Comment on updates** - Let reviewers know when fixes are pushed

## Environment Variables

```bash
# GitHub token (if not using gh auth)
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Default PR base branch
export GH_BASE_BRANCH="master"

# Default PR reviewer
export GH_DEFAULT_REVIEWER="@username"
```

## Troubleshooting

### "gh: command not found"

```bash
# Install GitHub CLI
# macOS:
brew install gh

# Linux:
sudo apt install gh

# Or download from: https://cli.github.com
```

### "Authentication required"

```bash
# Login
gh auth login

# Follow interactive prompts
```

### "Repository not found"

```bash
# Verify remote URL
git remote -v

# Should point to GitHub repo
# If not, add remote:
git remote add origin https://github.com/user/repo.git
```
