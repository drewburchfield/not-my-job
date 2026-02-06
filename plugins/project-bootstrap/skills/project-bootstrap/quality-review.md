---
name: quality-review
description: Run a thorough code quality and adherence review without needing a PR. Spawns a sub-agent for fresh context so the review does not consume the main session window. Use when you want to check code quality, find bugs, or verify adherence to a spec.
---

# Quality Review

A "PR review without a PR." This skill reviews all changed code for quality issues, logic errors, and spec adherence, then writes findings to disk so they persist across session compaction.

## How It Works

1. Read project context from `.claude/project-meta.json`
2. Determine review scope (what changed)
3. Spawn a review sub-agent via the Task tool
4. Write findings to `.claude/last-review.md`
5. Report summary back to the user

## Step-by-Step

### Step 1: Read Project Context

Read `.claude/project-meta.json` to get:
- `language`: project language
- `qualityGates`: commands for type check, lint, format

If the meta file does not exist, inform the user and suggest running `/bootstrap` first. You can still proceed with a manual review, but quality gate commands will need to be guessed or skipped.

### Step 2: Determine Scope

Decide what to review based on context:

1. **If on a feature branch** (not `main`/`master`): Review all commits since branching.
   ```bash
   git diff main...HEAD --name-only
   ```
   (Try `master` if `main` does not exist.)

2. **If on main/master with uncommitted changes**: Review staged + unstaged changes.
   ```bash
   git diff --name-only
   git diff --staged --name-only
   ```

3. **If no changes detected**: Tell the user there is nothing to review.

Collect the list of changed files. This becomes the review scope.

### Step 3: Look for Spec/PRD

Search for a spec or PRD file to anchor the review against:

1. Check for files matching: `*.prd.md`, `spec.md`, `PRD.md`, `SPEC.md`
2. Check if `CLAUDE.md` references a spec file
3. If found, the sub-agent will check adherence to the spec

### Step 4: Spawn Review Sub-Agent

Use the Task tool to spawn the review. The sub-agent gets a fresh context window and does not consume the main session.

Construct the prompt as follows (fill in the bracketed values):

```
You are reviewing code in a [LANGUAGE] project. Your job is to run quality checks and review changed files for issues.

## Quality Gates

Run these commands and report any failures:
- Type check: [TYPE_CHECK_COMMAND]
- Lint: [LINT_COMMAND]
- Format: [FORMAT_COMMAND]

## Changed Files to Review

[LIST OF CHANGED FILES]

## Review Checklist

For each changed file:
1. Read the file
2. Check for logic errors and bugs
3. Check for security issues (injection, hardcoded secrets, unsafe operations)
4. Check for dead code or unused imports
5. Check for missing error handling at system boundaries
6. Note any code that is hard to understand without comments

[IF SPEC EXISTS]
## Spec Adherence

The project spec is at [SPEC_PATH]. Read it and check:
- Are all specified features implemented?
- Does the implementation match the spec's requirements?
- Are there deviations that should be flagged?
[END IF]

## Output Format

Write your findings to `.claude/last-review.md` using this format:

# Quality Review - [DATE]

## Quality Gates
- Type check: PASS/FAIL (details if fail)
- Lint: PASS/FAIL (details if fail)
- Format: PASS/FAIL (details if fail)

## Findings

### Critical
- [file:line] Description of critical issue

### Warning
- [file:line] Description of warning

### Info
- [file:line] Suggestion or observation

## Spec Adherence (if applicable)
- Status of each spec requirement

## Summary
- Total files reviewed: N
- Critical: N | Warning: N | Info: N
```

### Step 5: Report Results

After the sub-agent completes:
1. Read `.claude/last-review.md`
2. Show the user a brief summary: number of findings by severity, any critical items
3. If there are critical findings, ask if the user wants you to fix them

## Important Notes

- **Always use Task tool** for the review. Do not run the review inline. The whole point is to use a fresh context window.
- **Findings on disk**: Written to `.claude/last-review.md` so they survive context compaction. The user can reference them later.
- **No GitHub needed**: This works on any local changes. No PR, no remote required.
- **Re-runnable**: Running `/quality-review` again overwrites the previous review file with fresh results.
