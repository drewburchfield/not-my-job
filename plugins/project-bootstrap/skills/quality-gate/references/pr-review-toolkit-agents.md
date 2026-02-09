# PR Review Toolkit Agents

Complete specifications for the pr-review-toolkit agents used in quality gate workflow.

## Agent Overview

The pr-review-toolkit provides 6 specialized review agents:

1. **code-reviewer** - General code quality and bug detection
2. **silent-failure-hunter** - Silent failure and error handling analysis
3. **code-simplifier** - Complexity reduction suggestions
4. **comment-analyzer** - Documentation accuracy validation
5. **pr-test-analyzer** - Test coverage quality assessment
6. **type-design-analyzer** - Type system design review (TypeScript/typed languages)

All agents operate on PR diffs and provide confidence-scored findings.

## code-reviewer

**Purpose**: Reviews code for bugs, logic errors, security vulnerabilities, code quality issues, and adherence to project conventions.

**What it catches**:
- Logic errors and bugs
- Security vulnerabilities (SQL injection, XSS, command injection, etc.)
- Code quality issues (complexity, readability, maintainability)
- Style violations and convention mismatches
- Performance anti-patterns
- Resource leaks (unclosed files, connections, etc.)
- Race conditions and concurrency issues

**Confidence scoring**: Only reports issues with high confidence to avoid false positives.

**Example findings**:
```
🔴 CRITICAL: SQL Injection vulnerability
  File: src/db/query.ts:42
  Issue: Concatenating user input into SQL query
  Fix: Use parameterized queries or ORM

🟠 HIGH: Potential null reference
  File: src/utils/parser.ts:18
  Issue: Accessing property without null check
  Fix: Add null guard or use optional chaining

🟡 MEDIUM: High cyclomatic complexity
  File: src/logic/processor.ts:67
  Issue: Function has complexity of 23 (threshold: 15)
  Fix: Extract sub-functions
```

**Integration**: Invoked automatically by `/review-pr`

## silent-failure-hunter

**Purpose**: Identifies silent failures, inadequate error handling, and inappropriate fallback behavior that masks problems.

**What it catches**:
- Empty catch blocks that suppress errors
- Generic catch-all error handlers that hide specific failures
- Fallback logic that continues silently after failures
- Missing error propagation
- Swallowed promise rejections
- Error handling that doesn't log or alert
- Failures that return success codes

**Why critical**: Silent failures are the most dangerous bugs - they appear to work but corrupt data or produce incorrect results.

**Example findings**:
```
🔴 CRITICAL: Empty catch block suppresses errors
  File: src/api/client.ts:89
  Issue: try { await fetch() } catch (e) { }
  Impact: Network failures go unnoticed
  Fix: Log error, notify user, or propagate

🟠 HIGH: Generic error handler masks specific failures
  File: src/processor.ts:45
  Issue: catch (error) { return default }
  Impact: Parse errors, validation errors all treated same
  Fix: Handle specific error types, log appropriately

🟡 MEDIUM: Promise rejection not handled
  File: src/async.ts:23
  Issue: asyncOperation() has no .catch()
  Impact: Unhandled rejection crashes process
  Fix: Add .catch() or use try/catch with await
```

**Integration**: Critical for quality gate - silent failures block merge

## code-simplifier

**Purpose**: Suggests simplifications and improvements for clarity, consistency, and maintainability while preserving all functionality.

**What it suggests**:
- Eliminating duplication
- Simplifying complex conditionals
- Reducing nesting depth
- Extracting magic numbers/strings to constants
- Removing dead code
- Using standard library functions instead of manual implementations
- Applying language idioms and patterns

**Philosophy**: "Make it work, then make it simple" - only suggests changes that preserve behavior.

**Example findings**:
```
🔵 INFO: Duplicate logic in multiple functions
  Files: src/utils/format.ts:12, src/utils/parse.ts:45
  Issue: Same date parsing logic repeated
  Fix: Extract to shared parseDate() utility

🔵 INFO: Complex conditional can be simplified
  File: src/validation.ts:34
  Issue: if (x === true) { return true } else { return false }
  Fix: return x

🔵 INFO: Manual array iteration
  File: src/transform.ts:67
  Issue: for loop to map array
  Fix: Use Array.map()
```

**Integration**: Findings are optional but improve code quality

## comment-analyzer

**Purpose**: Validates comments and documentation for accuracy, completeness, and long-term maintainability.

**What it checks**:
- Comments match actual code behavior
- Function/method documentation is accurate
- Parameter descriptions are correct
- Return value documentation matches implementation
- Comments don't contradict code
- Documentation isn't outdated (comment rot)
- TODOs have context and tracking

**Why matters**: Inaccurate comments are worse than no comments - they mislead developers.

**Example findings**:
```
🟠 HIGH: Comment contradicts code
  File: src/parser.ts:23
  Comment: "Returns null on error"
  Code: Actually throws exception
  Fix: Update comment to match behavior

🟡 MEDIUM: Missing parameter documentation
  File: src/api/handler.ts:45
  Issue: Function has 5 params, docstring documents 3
  Fix: Add missing parameter descriptions

🔵 INFO: Vague TODO without tracking
  File: src/processor.ts:89
  Issue: // TODO: optimize this
  Fix: Add issue link or specific improvement plan
```

**Integration**: Ensures documentation stays accurate

## pr-test-analyzer

**Purpose**: Reviews test coverage quality and identifies critical gaps, missing edge cases, and weak assertions.

**What it checks**:
- Test coverage for new functionality
- Edge case testing (null, empty, boundary values)
- Error path testing (failure scenarios)
- Integration test coverage
- Assertion quality (specific vs. vague)
- Test isolation (no interdependencies)
- Flaky test patterns

**Philosophy**: Coverage percentage isn't enough - test quality matters.

**Example findings**:
```
🔴 CRITICAL: No tests for new functionality
  File: src/features/new-handler.ts
  Issue: 200+ lines of new code, 0 tests
  Fix: Add unit tests for core logic

🟠 HIGH: Missing error path tests
  File: tests/parser.test.ts
  Issue: Only tests happy path, not parse failures
  Fix: Add tests for invalid input, malformed data

🟡 MEDIUM: Weak assertion
  File: tests/api.test.ts:45
  Issue: expect(result).toBeTruthy()
  Fix: Assert specific expected value
```

**Integration**: Critical for quality gate - untested code blocks merge

## type-design-analyzer

**Purpose**: Reviews type system design for encapsulation, invariant expression, usefulness, and enforcement (TypeScript/typed languages only).

**What it evaluates**:
- Type encapsulation (internal state hidden)
- Invariant expression (constraints in type system)
- Type usefulness (prevents invalid states)
- Type enforcement (compiler catches misuse)
- Discriminated unions for state machines
- Branded types for domain concepts

**Scoring**:
- **Encapsulation** (0-5): How well internal state is hidden
- **Invariant Expression** (0-5): How well constraints are expressed
- **Usefulness** (0-5): How much invalid behavior prevented
- **Enforcement** (0-5): How well compiler catches misuse

**Example findings**:
```
🟡 MEDIUM: Weak encapsulation
  File: src/models/user.ts
  Issue: All fields public, no validation
  Score: Encapsulation: 2/5
  Fix: Make fields private, add validated constructor

🟡 MEDIUM: Missing invariants
  File: src/types/email.ts
  Issue: type Email = string (no validation)
  Score: Invariant Expression: 1/5
  Fix: Use branded type or validation at boundary

🔵 INFO: Strong type design
  File: src/types/state-machine.ts
  Score: Encapsulation: 5/5, Invariants: 5/5
  Comment: Discriminated union prevents invalid states
```

**Integration**: Applies only to TypeScript/typed codebases

## Agent Invocation

All agents are invoked via the pr-review-toolkit skill:

```bash
/review-pr <pr-number>
```

This automatically:
1. Detects language/framework
2. Selects applicable agents (skips type-design-analyzer for JS, etc.)
3. Runs all agents in parallel
4. Consolidates findings
5. Returns prioritized list (Critical → High → Medium → Low → Info)

## Finding Priority

Agents assign priority based on impact:

**🔴 CRITICAL** - Blocks merge
- Security vulnerabilities
- Silent failures that corrupt data
- Untested core functionality
- Breaking changes

**🟠 HIGH** - Should fix before merge
- Likely bugs
- Missing error handling
- Poor encapsulation in critical paths
- Missing edge case tests

**🟡 MEDIUM** - Improve if time permits
- Code smells
- Complexity issues
- Minor security concerns
- Documentation gaps

**🔵 INFO** - Nice to have
- Style suggestions
- Simplification opportunities
- Refactoring ideas

Quality gate requires all CRITICAL and HIGH findings resolved before merge.

## Confidence Filtering

All agents use confidence-based filtering to avoid false positives:

- **High Confidence (>80%)**: Report as-is
- **Medium Confidence (50-80%)**: Report with caveat
- **Low Confidence (<50%)**: Suppress (don't report)

This ensures quality gate focuses on real issues, not noise.

## Integration with Quality Gate

Quality gate uses agents in two passes:

**First Pass (Step 3)**:
- Runs all applicable agents
- Groups findings by priority
- Presents to user for remediation
- Tracks which findings addressed

**Second Pass (Step 7)**:
- Re-runs code-reviewer only (quick check)
- Validates remediations didn't introduce new issues
- Combines with Devin findings

This two-pass approach catches issues early and validates fixes.

## Example Agent Output

```
📊 PR Review Results for #123

🔴 CRITICAL (2 findings)
  1. [code-reviewer] SQL Injection in src/db/query.ts:42
  2. [silent-failure-hunter] Empty catch block in src/api/client.ts:89

🟠 HIGH (3 findings)
  3. [pr-test-analyzer] No tests for new feature in src/features/handler.ts
  4. [code-reviewer] Null reference in src/utils/parser.ts:18
  5. [silent-failure-hunter] Unhandled promise rejection in src/async.ts:23

🟡 MEDIUM (5 findings)
  6. [comment-analyzer] Outdated comment in src/processor.ts:45
  7. [type-design-analyzer] Weak encapsulation in src/models/user.ts
  8. [code-simplifier] Duplicate logic in src/utils/format.ts:12
  9. [code-reviewer] High complexity in src/logic/processor.ts:67
  10. [pr-test-analyzer] Weak assertion in tests/api.test.ts:45

🔵 INFO (2 findings)
  11. [code-simplifier] Manual iteration in src/transform.ts:67
  12. [type-design-analyzer] Strong design in src/types/state-machine.ts ✓

⚠️  Quality Gate Status: BLOCKED
    Must resolve 2 CRITICAL and 3 HIGH findings before merge.
```

## Best Practices

**When findings are unclear**:
- Read agent reasoning (included in output)
- Check linked file/line number
- Review git diff for context
- Ask for clarification in PR comment

**When disagreeing with finding**:
- Explain reasoning in PR comment
- Mark as "wont-fix" with justification
- Quality gate requires explicit acknowledgment

**When findings conflict**:
- Prioritize by severity (Critical > High)
- Consider maintainability vs. performance trade-offs
- Ask user if unclear which direction to take

**When agents miss issues**:
- Agent review is thorough but not exhaustive
- Manual review still valuable
- Report agent gaps to improve future reviews

## Summary

The pr-review-toolkit agents provide comprehensive, automated code review covering:
- **code-reviewer**: General quality and bugs
- **silent-failure-hunter**: Error handling (critical!)
- **code-simplifier**: Maintainability improvements
- **comment-analyzer**: Documentation accuracy
- **pr-test-analyzer**: Test coverage quality
- **type-design-analyzer**: Type system design

Quality gate uses these agents to enforce code quality standards before merge, ensuring shipped code is secure, correct, and maintainable.
