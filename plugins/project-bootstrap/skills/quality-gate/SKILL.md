---
name: quality-gate
description: This skill should be used when the user asks to "quality gate", "run quality gate", "review and merge", "PR review cycle", or mentions completing a phase/milestone and wanting comprehensive review before merge. Implements compound PR review with agent reviews, Devin.ai integration, remediation cycles, and merge.
version: 0.1.0
---

# Quality Gate: Compound PR Review Cycle

Implements a structured PR review and merge workflow with multiple review passes, automated remediation, Devin.ai integration, and Linear issue tracking.

## Purpose

Quality gate enforces a rigorous review cycle before merging code:
1. Create PR from current work
2. Run comprehensive agent-based reviews (code quality, silent failures, test coverage, etc.)
3. Remediate all findings
4. Wait for Devin.ai to analyze the PR (60 second pause)
5. Second review pass incorporating agent + Devin feedback
6. Final remediation and merge if passing
7. Update Linear issue status

This ensures code quality, catches edge cases, and integrates external AI review (Devin.ai) into the workflow.

## When to Use

Invoke quality gate after completing:
- A Linear issue (NAS-577, NAS-578, etc.)
- A milestone phase (Phase 1, Phase 2, etc.)
- A feature branch ready for merge
- Any work that should pass comprehensive review before integration

## Usage

**Four usage modes**:

**1. Auto-detect** (recommended):
```bash
/quality-gate
```
Detects issue from branch/commits. If no issue found, prompts for standalone mode.

**2. Explicit issue**:
```bash
/quality-gate NAS-577
```
Manually specify Linear issue number.

**3. Standalone** (no Linear):
```bash
/quality-gate --no-issue
```
Full PR workflow WITHOUT Linear integration. Use for hotfixes, docs, experiments.

**4. Local-only**:
```bash
/quality-gate --local
```
Review locally WITHOUT creating PR or pushing.

### Mode Behaviors

**Auto-detect** (`/quality-gate`):
- Tries to detect issue from: branch name → commit messages → Linear API
- If found: Runs with Linear integration
- If not found: Prompts "Run in standalone mode? (Y/n)"
- If standalone: Full PR review, no Linear updates

**Explicit** (`/quality-gate NAS-577`):
- Uses specified issue
- Runs with Linear integration
- Skips detection logic

**Standalone** (`/quality-gate --no-issue`):
- Full PR review cycle
- NO Linear integration
- NO issue detection or validation
- Use for: hotfixes, docs, experiments

**Local** (`/quality-gate --local`):
- ✅ Agent reviews on local diff
- ✅ Remediate locally
- ✅ Commit fixes
- ❌ NO PR creation
- ❌ NO push to remote
- ❌ NO Devin wait
- ❌ NO merge
- ❌ NO Linear updates
- **STOPS completely** (you decide next steps)

### When to Use Each

- **During development**: `/quality-gate --local` (iterate privately)
- **Ready to ship**: `/quality-gate` (full PR cycle)
- **Explicit tracking**: `/quality-gate NAS-577` (when branch name unclear)
- **No tracking needed**: `/quality-gate --no-issue` (hotfixes, docs, quick fixes)

## Mode Comparison

| Feature | `--local` | Default | Explicit Issue |
|---------|-----------|---------|----------------|
| **Local review** | ✅ Yes | ✅ Yes (pre-flight) | ✅ Yes (pre-flight) |
| **Local remediation** | ✅ Yes | ✅ Yes (pre-flight) | ✅ Yes (pre-flight) |
| **Push to remote** | ❌ No | ✅ Yes | ✅ Yes |
| **Create PR** | ❌ No | ✅ Yes | ✅ Yes |
| **PR agent reviews** | ❌ No | ✅ Yes | ✅ Yes |
| **Devin wait (60s)** | ❌ No | ✅ Yes | ✅ Yes |
| **PR remediation** | ❌ No | ✅ Yes | ✅ Yes |
| **Merge** | ❌ No | ✅ Yes | ✅ Yes |
| **Linear updates** | ❌ No | ✅ If detected | ✅ Yes |
| **Issue detection** | N/A | ✅ Auto | Skipped (explicit) |

**Key Points**:
- `--local` is **completely self-contained** (never advances to PR)
- Default mode **includes local review first** (catches issues before PR creation)
- Both PR modes require user confirmation before merge (no auto-merge)

**Typical workflow**:
1. **Iterate**: `/quality-gate --local` (fast feedback, local only)
2. **Ship**: `/quality-gate` (full PR cycle with Devin + agents)

## Workflow

Quality gate has two distinct workflows depending on mode:

### Full PR Workflow (default `/quality-gate`)

1. **Local Review First** (pre-flight)
2. Create PR
3. Agent reviews on PR
4. First remediation
5. Wait 60s for Devin
6. Second remediation
7. Merge

### Local-Only Workflow (`/quality-gate --local`)

1. **Local Review** (on uncommitted or committed-not-pushed changes)
2. Remediate locally
3. **STOP** (no PR, no push, user decides next step)

---

### Step 1: Validate Prerequisites and Detect Issue

Before starting the quality gate cycle, verify prerequisites and detect or validate the Linear issue.

**Git Status:**
- Current branch exists and is not `master` or `main`
- All changes are committed (no uncommitted work)
- Branch is pushed to origin (or will be pushed)

**Issue Detection** (if not provided):

If no issue number provided, attempt auto-detection:

1. **From branch name**: Extract issue from branch name patterns:
   ```bash
   # Get current branch
   BRANCH=$(git branch --show-current)

   # Extract issue from common patterns:
   # - feature/nas-577-description → NAS-577
   # - drewburchfield/nas-577-description → NAS-577
   # - nas-577-description → NAS-577
   # - fix/NAS-577 → NAS-577

   # Case-insensitive regex: nas-?(\d+)
   ```

2. **From recent commits**: If branch name has no issue, check recent commits for "Fixes NAS-XXX" or "Closes #XXX":
   ```bash
   git log -10 --pretty=%s | grep -oE "(NAS|#)-?[0-9]+" | head -1
   ```

3. **From Linear board**: If still not found, fetch Linear issues with current branch name:
   ```bash
   linear issue list --filter "gitBranchName contains '$(git branch --show-current)'"
   ```

4. **Prompt user**: If all detection fails, ask user to provide issue number

**Issue Validation** (if issue detected or provided):
- Issue number is valid (format: NAS-XXX or #XXX)
- Issue exists in Linear
- Issue is not already Done or Archived
- Issue has project and milestone assigned

**Detection Examples**:
```bash
# Branch: feature/nas-577-setup → Auto-detects: NAS-577 → Linear mode
/quality-gate

# Branch: improve-logging (no issue) → Check commits → Find "Fixes NAS-580" → Linear mode
/quality-gate

# Branch: experiment → No issue found → Standalone mode (user confirms)
/quality-gate
> "No Linear issue detected. Run in standalone mode? (Y/n)"
> Y
> "Running quality gate in standalone mode (no Linear integration)"

# Manual override always works
/quality-gate NAS-577

# Explicit standalone mode
/quality-gate --no-issue
```

**Standalone Mode Behavior**:
When no Linear issue is found or `--no-issue` is specified:
- ✅ Full PR review cycle runs (all agents, Devin integration)
- ✅ Remediation passes work normally
- ✅ Merge workflow works
- ❌ No Linear issue status updates
- ❌ No Linear comments with PR link

This allows quality gate to be used for:
- Quick fixes without Linear tracking
- Experimental branches
- Documentation updates
- Hotfixes
- Third-party contributions

If prerequisites fail, report what's missing and exit. Do not proceed with incomplete setup.

### Step 2: Local Review First (Pre-flight)

**Before creating PR**, run local review on current changes to catch issues early:

```bash
# Get local diff
git diff origin/master..HEAD
```

Run agent reviews on local diff:
- **code-reviewer**: Catch bugs before PR
- **silent-failure-hunter**: Ensure error handling is correct
- **code-simplifier**: Clean up before team sees it
- **comment-analyzer**: Fix documentation issues
- **pr-test-analyzer**: Verify test coverage
- **type-design-analyzer**: Validate type design (if TypeScript)

**If findings exist**:
```
📊 Pre-flight Local Review

🔴 CRITICAL (1 finding)
  1. [silent-failure-hunter] Empty catch block in discord-client.ts:89

Pre-flight check FAILED. Fix locally before creating PR?
(Y/n)
```

If user confirms, remediate locally:
```bash
# Fix issue
vim discord-client.ts

# Commit locally
git add -A
git commit -m "Fix empty catch block (pre-flight review)"

# Re-run pre-flight
# (repeat until clean)
```

**If pre-flight passes**:
```
✅ Pre-flight review passed!
   No blocking issues found locally.
   Ready to create PR.

Proceed with PR creation? (Y/n)
```

This catches issues BEFORE creating the PR, reducing PR review cycles.

### Step 3: Create PR

Use GitHub CLI to create PR from current branch:

```bash
# Get current branch name
BRANCH=$(git branch --show-current)

# Create PR with Linear issue reference
gh pr create \
  --title "$(git log -1 --pretty=%s)" \
  --body "Fixes linear.app/nashburch/issue/${ISSUE_NUMBER}

$(git log --oneline origin/master..HEAD --pretty=format:'- %s')

## Changes
[Brief description of changes]

## Testing
[How this was tested]

## Review Focus
[What reviewers should focus on]" \
  --base master \
  --head "$BRANCH"
```

Capture the PR URL and number for subsequent operations.

### Step 4: First Agent Review Pass

Run comprehensive PR review using pr-review-toolkit agents. These are the critical agents that catch issues:

**code-reviewer**
- Checks code quality, style, best practices
- Identifies bugs, logic errors, security issues
- Validates project conventions

**silent-failure-hunter**
- Detects silent failures and inadequate error handling
- Identifies inappropriate fallback behavior
- Catches suppressed errors in try/catch blocks

**code-simplifier**
- Suggests simplifications while preserving functionality
- Identifies over-engineering
- Recommends clarity improvements

**comment-analyzer**
- Validates comment accuracy
- Detects comment rot and technical debt
- Ensures documentation matches code

**pr-test-analyzer**
- Reviews test coverage quality
- Identifies missing edge cases
- Validates test assertions

**type-design-analyzer** (if TypeScript/typed code)
- Reviews type design quality
- Checks encapsulation and invariants
- Validates type safety

Invoke the review:

```bash
/review-pr <pr-number>
```

The pr-review-toolkit will run all applicable agents and provide consolidated findings.

### Step 5: First Remediation Pass

For each finding from agent reviews:

1. **Categorize by severity**: Critical, High, Medium, Low
2. **Address Critical and High first**: These block merge
3. **Implement fixes**: Make code changes to address findings
4. **Commit fixes**: Use descriptive commit messages referencing findings
5. **Push to PR branch**:
   ```bash
   git add -A
   git commit -m "Address PR review findings: [summary]

   - Fix: [specific issue]
   - Improve: [specific issue]
   - Add: [specific test/validation]

   Addresses findings from code-reviewer, silent-failure-hunter"

   git push
   ```

Track which findings were addressed and which were deferred (with justification).

### Step 6: Wait for Devin.ai

After pushing remediation commits, pause for 60 seconds to allow Devin.ai to analyze the PR:

```bash
echo "⏳ Waiting 60 seconds for Devin.ai to analyze PR..."
sleep 60
```

**Why 60 seconds?**
Devin.ai is configured to automatically comment on PRs with findings. The 60-second pause ensures Devin has time to:
- Detect the new PR or push
- Analyze the changes
- Post comments with findings

After the pause, fetch all PR comments.

### Step 7: Collect All Feedback

Fetch comments from both agent reviews and Devin.ai:

```bash
# Get PR comments
gh pr view <pr-number> --comments --json comments | jq -r '.comments[] | "\(.author.login): \(.body)"'
```

Parse comments to identify:
- **Agent findings**: From pr-review-toolkit agents
- **Devin findings**: Comments from Devin.ai user
- **Other comments**: Manual reviewer comments (if any)

Consolidate all findings into a single list for second remediation pass.

### Step 8: Second Review Pass

With all feedback collected (agents + Devin + manual), perform a second review:

1. **Verify first remediation**: Check that previous fixes are correct
2. **Address new findings**: Handle Devin.ai findings and any new issues
3. **Cross-check**: Ensure fixes don't introduce new problems
4. **Run tests**: If project has tests, run them to verify
5. **Final commit**:
   ```bash
   git add -A
   git commit -m "Second remediation pass: address Devin findings

   - Fix: [Devin finding 1]
   - Improve: [Devin finding 2]
   - Validate: [cross-check item]

   All agent + Devin findings addressed."

   git push
   ```

### Step 9: Final Review

Before merge, perform final validation:

**Code Quality:**
- All Critical and High findings resolved
- Medium/Low findings resolved or explicitly deferred
- Code follows project conventions

**Testing:**
- Existing tests pass
- New tests added where needed
- Edge cases covered

**Documentation:**
- Comments accurate
- README updated if needed
- Linear issue description matches implementation

**Git Hygiene:**
- Commit messages are clear
- No merge conflicts
- Branch is up to date with master

If any validation fails, loop back to remediation. If all pass, proceed to merge.

### Step 10: Merge Decision

Present merge options to user:

```
✅ Quality gate passed!

All findings addressed:
- Agent reviews: X findings resolved
- Devin findings: Y findings resolved
- Tests: Passing
- Conflicts: None

Options:
1. Merge now (squash and merge)
2. Merge with rebase
3. Request manual review first
4. Exit (I'll merge manually)

Choice?
```

Wait for user input. Do not merge automatically without confirmation.

### Step 11: Merge and Update Linear

If user approves merge:

```bash
# Merge PR (squash by default)
gh pr merge <pr-number> --squash --delete-branch

# Update Linear issue status (if in Linear mode)
# (Use Linear CLI or API to mark issue as Done)

# Clean up local branch
git checkout master
git pull
git branch -d <branch-name>
```

**Linear Mode** (issue detected):
```
✅ Merged and cleaned up!

- PR: Squashed and merged
- Branch: Deleted
- Linear: Issue NAS-577 marked as Done
- Local: Switched to master, pulled latest

Ready for next issue!
```

**Standalone Mode** (no issue):
```
✅ Merged and cleaned up!

- PR: Squashed and merged
- Branch: Deleted
- Linear: N/A (standalone mode)
- Local: Switched to master, pulled latest

Ready for next work!
```

## Local Mode Workflow

Local mode runs agent reviews without creating PR or pushing to remote. Use for pre-flight validation.

### Local Mode Steps

**Step 1: Detect Changes**
```bash
# Check for uncommitted changes
git status

# Or check committed but unpushed changes
git log origin/master..HEAD
```

Run agent reviews on whichever changes exist (uncommitted or committed-not-pushed).

**Step 2: Run Agent Reviews**

Since no PR exists, run agent reviews on local diff:
```bash
# For uncommitted changes
git diff

# For committed changes
git diff origin/master..HEAD
```

Invoke all applicable agents with the diff as input:
- **code-reviewer**: Review code quality on diff
- **silent-failure-hunter**: Check error handling in diff
- **code-simplifier**: Suggest simplifications for diff
- **comment-analyzer**: Validate comments in diff
- **pr-test-analyzer**: Check test coverage for new code (if tests present)
- **type-design-analyzer**: Review type design in diff (if TypeScript)

Note: Agents may need to read full file context, not just diff. Use git diff with context (`-U10` for 10 lines context).

**Step 3: Present Findings**

Show all findings with same priority structure:
```
📊 Local Review Results

🔴 CRITICAL (1 finding)
  1. [silent-failure-hunter] Empty catch block in discord-client.ts:89

🟠 HIGH (2 findings)
  2. [code-reviewer] Null reference in queue-processor.ts:45
  3. [pr-test-analyzer] No tests for queue logic

🟡 MEDIUM (3 findings)
  ...

✅ Local Review Status: BLOCKED
   Must resolve 1 CRITICAL and 2 HIGH findings
```

**Step 4: Remediate Locally**

Fix findings and commit locally:
```bash
# Fix issues
vim discord-client.ts
vim queue-processor.ts

# Commit fixes locally (no push)
git add -A
git commit -m "Address local review findings

- Fix: Empty catch block (silent-failure-hunter)
- Fix: Null reference (code-reviewer)
- Add: Queue processor tests (pr-test-analyzer)"

# DO NOT PUSH
```

**Step 5: Re-run Review**

After remediation, re-run agents on updated diff:
```bash
/quality-gate --local
```

If findings remain, repeat remediation. If clean, report success:
```
✅ Local review passed!

All findings addressed:
- Agent reviews: 6 findings resolved
- Commits: 2 local commits (not pushed)

Next steps:
1. Review commits: git log -2
2. Push when ready: git push
3. Create PR: /quality-gate (without --local)

Local changes ready for PR creation.
```

**Step 6: Exit (No Further Action)**

**IMPORTANT**: Local mode stops here completely. It does NOT:
- ❌ Auto-advance to PR creation
- ❌ Prompt to push
- ❌ Suggest running full quality-gate

Work remains on local branch, unpushed. User maintains full control of next steps.

**User options after local review passes**:
- Review commits: `git log -2`
- Make more changes: Continue working
- Push manually: `git push` (when ready)
- Create PR manually: `gh pr create` or `/quality-gate` without --local
- Abandon work: `git reset` or delete branch
- Do nothing: Leave work local indefinitely

Local mode is **completely self-contained**. It provides feedback, you act on it, done.

### Local Mode Use Cases

**Pre-flight validation**:
```bash
# Before pushing risky changes
/quality-gate --local

# Review findings, fix issues
# Then push with confidence
```

**Self-review before team review**:
```bash
# Want agent feedback before team sees it
/quality-gate --local

# Fix issues privately
# Then create PR
```

**Experimental work**:
```bash
# Testing an approach, not sure if viable
/quality-gate --local

# If agents find major issues, might abandon
# If clean, proceed to PR
```

**Quick validation**:
```bash
# Just want to check for obvious issues
/quality-gate --local

# Fast feedback loop, no remote interaction
```

## Integration Points

### Linear Integration

Use Linear CLI or MCP to:
- Fetch issue details (title, description, milestone)
- Validate issue status (must not be Done/Archived)
- Update issue status to Done after merge
- Add comment with PR link

Example:
```bash
# Get issue details
linear issue <issue-id>

# Update status
linear issue update <issue-id> --status "Done"

# Add comment
linear issue comment <issue-id> "Merged in PR #<pr-number>"
```

### GitHub CLI Integration

All PR operations use `gh` CLI:
- `gh pr create` - Create PR
- `gh pr view` - Fetch PR details and comments
- `gh pr merge` - Merge PR
- `gh pr comment` - Add comment (if needed)

Ensure `gh` is authenticated and configured for the repository.

### pr-review-toolkit Integration

The pr-review-toolkit skill provides the agent review functionality. Invoke with:

```bash
/review-pr <pr-number>
```

This automatically runs all applicable agents and returns consolidated findings. The quality-gate skill processes these findings for remediation.

## Error Handling

Handle common failure scenarios:

**Git errors:**
- Uncommitted changes → Prompt to commit or stash
- Not on feature branch → Cannot create PR from master
- Push failures → Check remote, authentication

**GitHub errors:**
- PR already exists → Fetch existing PR instead of creating
- Merge conflicts → Prompt user to resolve, then retry
- API rate limits → Wait and retry

**Linear errors:**
- Issue not found → Verify issue number format
- Status update fails → Continue with merge, manual Linear update

**Review errors:**
- Agent review fails → Retry once, then proceed with manual review
- Devin timeout → Proceed without Devin findings (note in PR comment)

Always provide clear error messages and recovery options. Never leave the workflow in an inconsistent state.

## Configuration

Quality gate respects these conventions:

**Branch naming:**
- Feature branches: `feature/nas-XXX-description` or `drewburchfield/nas-XXX-description`
- Extracts issue number from branch name if not provided

**Commit message format:**
- First line: Summary (50 chars)
- Body: Details, references, co-authors

**PR template:**
- Title: Issue title or last commit message
- Body: Fixes link, changes, testing, review focus

**Merge strategy:**
- Default: Squash and merge
- Option: Rebase (for clean history)
- Deletes branch after merge

## Examples

### Example 1: Complete Phase 1 Issue

```bash
# After completing NAS-577 work
git add -A
git commit -m "Complete project structure setup"
git push

# Run quality gate
/quality-gate NAS-577

# Workflow runs:
# 1. Creates PR
# 2. Runs agent reviews
# 3. Shows findings, remediates
# 4. Waits 60s for Devin
# 5. Fetches all comments
# 6. Second remediation
# 7. Presents merge options
# 8. Merges and updates Linear
```

### Example 2: Failed Review (Retry)

```bash
/quality-gate NAS-578

# Agent finds critical issues
# Remediation applied
# Devin finds additional issues
# Second remediation applied
# Final review FAILS (tests broken)

# Skill reports:
# "❌ Quality gate failed: Tests failing
#  Fix tests and re-run /quality-gate NAS-578"

# User fixes tests
git add -A
git commit -m "Fix failing tests"
git push

# Retry quality gate
/quality-gate NAS-578

# This time passes and merges
```

### Example 3: Manual Intervention

```bash
/quality-gate NAS-579

# Workflow completes successfully
# Presents merge options

# User chooses: "3. Request manual review first"

# Skill responds:
# "✅ Quality gate passed, awaiting manual review
#  PR: https://github.com/user/repo/pull/123
#  Run /quality-gate NAS-579 again after review to merge"
```

### Example 4: Local Mode (Pre-flight Check)

```bash
# Working on NAS-578, not ready to push yet
git checkout -b feature/nas-578-discord-client
# ... write code ...
git add -A
git commit -m "WIP: Discord client implementation"

# Run local review before pushing
/quality-gate --local

# Agent reviews run on local diff
# Finds issues:
# 🔴 CRITICAL: Silent failure in message handler
# 🟠 HIGH: Missing error handling in queue write

# Fix issues locally
vim discord-client.ts
git add -A
git commit -m "Fix error handling per local review"

# Re-run local review
/quality-gate --local

# Passes!
# ✅ Local review passed!
#    All findings addressed
#    Ready to push when you want

# Now confident to push and create PR
git push
/quality-gate  # Full cycle with PR + Devin
```

## Best Practices

**Before invoking quality gate:**
- Ensure all work is committed
- Run local tests if available
- Review your own changes first
- Write clear commit messages

**During remediation:**
- Address Critical/High findings first
- Group related fixes in single commits
- Reference finding IDs in commit messages
- Don't introduce new issues while fixing

**After merge:**
- Pull latest master immediately
- Start next issue from clean master
- Update Linear board view
- Celebrate shipped code! 🎉

## Troubleshooting

**"Not on feature branch" error:**
- Check current branch: `git branch --show-current`
- Cannot run from master/main
- Create feature branch: `git checkout -b feature/nas-XXX-description`

**"PR already exists" error:**
- Fetch existing PR: `gh pr view`
- If abandoned, close and create new: `gh pr close <num> && gh pr create`

**Agent review hangs:**
- Check pr-review-toolkit is available: `/review-pr --help`
- Network issues may affect agent execution
- Retry once, then proceed with manual review

**Devin doesn't comment:**
- Verify Devin.ai is configured for repository
- Check PR is public/accessible to Devin
- Proceed without Devin findings if timeout (note in PR)

**Merge conflicts:**
- Cannot auto-merge with conflicts
- Resolve conflicts manually: `git merge master` in feature branch
- Push conflict resolution
- Re-run quality gate

## Additional Resources

### Reference Files

For detailed agent specifications:
- **`references/pr-review-toolkit-agents.md`** - Complete agent descriptions and capabilities

For integration details:
- **`references/linear-integration.md`** - Linear CLI/API usage patterns
- **`references/github-cli.md`** - GitHub CLI commands and patterns

### Example Files

Working examples:
- **`examples/successful-quality-gate.log`** - Complete successful run
- **`examples/failed-then-passed.log`** - Failed first pass, succeeded second
- **`examples/devin-findings.md`** - Sample Devin.ai comments

### Scripts

Utility scripts:
- **`scripts/parse-pr-comments.sh`** - Extract findings from PR comments
- **`scripts/update-linear-status.sh`** - Update Linear issue status
- **`scripts/validate-pr-ready.sh`** - Check PR prerequisites

## Validation Checklist

Before considering quality gate complete:

**Prerequisites:**
- [ ] On feature branch (not master/main)
- [ ] All changes committed
- [ ] Branch pushed to origin
- [ ] Linear issue valid and not Done

**First Review:**
- [ ] PR created successfully
- [ ] All agents ran (code-reviewer, silent-failure-hunter, etc.)
- [ ] Critical/High findings addressed
- [ ] Commits pushed

**Devin Integration:**
- [ ] 60 second pause completed
- [ ] PR comments fetched
- [ ] Devin findings identified

**Second Review:**
- [ ] All feedback consolidated
- [ ] Devin findings addressed
- [ ] Cross-check completed
- [ ] Final commits pushed

**Merge:**
- [ ] Final validation passed
- [ ] User confirmed merge decision
- [ ] PR merged successfully
- [ ] Branch deleted
- [ ] Linear issue updated to Done

If any checklist item fails, identify issue and provide recovery path.

## Summary

Quality gate implements a rigorous, repeatable PR review workflow:

1. **Automated agent reviews** catch code quality issues
2. **Devin.ai integration** provides external AI analysis
3. **Multiple remediation passes** ensure thorough fixes
4. **Linear integration** keeps issue tracking in sync
5. **User confirmation** before irreversible merge

This ensures high code quality, catches edge cases, and maintains clean git/Linear history across all phases of development.

Invoke with `/quality-gate <issue-number>` after completing any issue or milestone.
