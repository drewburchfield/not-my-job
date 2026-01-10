---
name: braintrust
description: Orchestrate other AI CLIs (Gemini, Codex, Claude Code) for second opinions, research, codebase analysis, design review, security audits, and parallel research
---

# Braintrust

Consult your AI braintrust - the other AI CLIs available in your environment - for second opinions, research, and codebase analysis.

> **Important:** Run ALL braintrust CLI invocations (including health checks and consultations) as background tasks using `run_in_background: true`. This allows monitoring progress instead of blocking. Launch multiple checks/consultations in parallel when possible.

## Why Multi-Model Collaboration Works

Each AI model has different training data, reasoning patterns, and blind spots. Research and developer experience consistently shows:

- **When a model introduces a bug, it struggles to fix it** - but a different model often spots it instantly
- **Combined approaches outperform individual models** on complex tasks
- **Claude excels at detailed, conversational coding work; Gemini provides strategic overview**
- **Different perspectives catch edge cases one model would miss**

The result feels like "working with a small, experienced development team" rather than a single assistant.

## Core Concept

**All three CLIs are available as your braintrust** - including calling Claude as an external subagent from within Claude Code:

| You Are In | Your Braintrust | How to Call Claude |
|------------|-----------------|-------------------|
| Claude Code | Gemini + Codex + Claude | Use Task tool with subagent (spawns separate Claude instance) |
| Gemini CLI | Claude + Codex | `claude -p "query" --model sonnet --output-format json` |
| Codex CLI | Claude + Gemini | `claude -p "query" --model sonnet --output-format json` |

### Calling Claude from Claude Code

When running in Claude Code, you can consult a separate Claude instance via the Task tool:

```
Use the Task tool with subagent_type="Explore" or "general-purpose" to get a fresh Claude perspective on your problem. This spawns an independent Claude session with its own context.
```

This means **all three models are always available** regardless of which harness you're in.

## Prerequisites

**Skip health checks by default** - just try to use the braintrust. Only run diagnostics if a consultation fails.

**If a CLI fails**, run these to diagnose:

```bash
# Diagnostic health checks (only run if needed)
claude -p "test" --model haiku --output-format json &>/dev/null && echo "Claude: OK" || echo "Claude: FAILED"
gemini "test" -m gemini-3-flash-preview -o json &>/dev/null && echo "Gemini: OK" || echo "Gemini: FAILED"
codex exec --json "test" &>/dev/null && echo "Codex: OK" || echo "Codex: FAILED"
```

**If missing, install:**
- Claude: `npm install -g @anthropic-ai/claude-code`
- Gemini: `npm install -g @google/gemini-cli`
- Codex: `npm install -g @openai/codex`

## Braintrust Defaults

**Always use explicit capable models** - CLI headless modes auto-route to weaker models when called externally.

| CLI | Default Command | Fast Option |
|-----|-----------------|-------------|
| **Claude** | `claude -p "query" --model sonnet --output-format json` | `--model haiku` |
| **Gemini** | `gemini "query" -m gemini-3-pro-preview -o json` | `-m gemini-3-flash-preview` |
| **Codex** | `codex exec --json "query"` | N/A |

## When to Consult the Braintrust

### High-Value Use Cases

| Use Case | Best Model(s) | Why It Works |
|----------|---------------|--------------|
| **Design & Frontend Review** | Gemini 3 Pro | Leads WebDev Arena (1487 Elo), 35% higher accuracy on UI challenges, generates pixel-perfect code from sketches |
| **Architecture Review** | Gemini (primary) | 1M context analyzes 40K+ lines holistically; understands how components interact across entire codebase |
| **Cross-Model Code Review** | Different than author | The model that wrote code has blind spots to its own bugs; fresh eyes catch issues instantly |
| **System-Wide Bug Investigation** | Gemini + Claude | Gemini for cross-file pattern detection, Claude for detailed fix implementation |
| **Security Audit** | Parallel all three | Verify auth patterns, SQL injection protection, rate limiting - each model catches different vulnerabilities |
| **Design System Extraction** | Gemini 3 Pro | Analyzes brand elements (colors, fonts, spacing), generates consistent component libraries |
| **Framework Migration** | Gemini | Side-by-side comparisons (React→Vue, Django→Flask), translates patterns with full context |
| **Parallel Research** | All three | 3x speed, diverse sources, cross-validate findings |

### Recommended Workflows

**The Peer Review Pattern** (most impressive results):
1. Implement with your primary harness (e.g., Claude Code)
2. Request braintrust review: "Ask Gemini to review these changes as if they're a peer developer"
3. Braintrust catches issues the implementation pair missed (wrong patterns, memory leaks, inconsistencies)

**The Strategic + Tactical Pattern**:
1. Gemini for big-picture strategy (architecture, codebase-wide patterns)
2. Claude/Codex for detailed implementation
3. Different model for final review

**The Bug Investigation Pattern**:
1. Claude handles individual components well
2. For system-wide issues spanning multiple files → Gemini's 1M context sees the full picture
3. Back to Claude for implementing the fix

## Invocation Patterns

### Standard Consultation

Get a second opinion from the braintrust:

```bash
# From Claude Code - consult Gemini
gemini "Review this implementation approach: [CONTEXT]" -m gemini-3-pro-preview -o json | jq -r '.response'

# From Claude Code - consult Codex
codex exec --json "Review this implementation approach: [CONTEXT]" | jq -rs 'map(select(.item.type? == "agent_message")) | last | .item.text'

# From Gemini - consult Claude
claude -p "Review this implementation approach: [CONTEXT]" --model sonnet --output-format json | jq -r '.result'
```

### Design & Frontend Review (Gemini 3's Strength)

Gemini 3 Pro leads the WebDev Arena with 1487 Elo and shows 35% higher accuracy on frontend challenges. It thinks in design systems, not individual components:

```bash
# Review UI component design
gemini "@src/components/ Review the design consistency. Are we following a coherent design system? Check spacing, typography scale, color usage." -m gemini-3-pro-preview -o json | jq -r '.response'

# Generate component from sketch (drag image into terminal)
gemini "@sketch.png Generate a React component with Tailwind CSS that matches this design exactly" -m gemini-3-pro-preview -o json

# Extract design system from existing code
gemini "@src/styles/ @src/components/ Extract the implicit design system: color palette, spacing scale, typography, component patterns" -m gemini-3-pro-preview -o json | jq -r '.response'

# Review accessibility
gemini "@src/components/ Audit for accessibility: semantic HTML, ARIA attributes, keyboard navigation, color contrast" -m gemini-3-pro-preview -o json | jq -r '.response'
```

### Codebase Analysis (Gemini's 1M Context)

Gemini has 1M token native context - ideal for whole-codebase work. Testing shows it can analyze 40K+ lines while maintaining architectural understanding:

```bash
# Analyze entire codebase
gemini "@src/ @lib/ What architectural patterns are used?" -m gemini-3-pro-preview -o json

# Find patterns across files
gemini "@./ How is error handling implemented across the codebase?" -m gemini-3-pro-preview -o json

# Compare implementations
gemini "@src/auth/ @src/api/ Are these using consistent patterns?" -m gemini-3-pro-preview -o json

# Holistic refactoring suggestions
gemini "@src/ Suggest refactoring improvements that require understanding of the full system, not just individual files" -m gemini-3-pro-preview -o json
```

### Maximum Reasoning (Hard Problems)

For the hardest problems, use flagship models:

```bash
# Claude Opus (200K context limit)
claude -p "[HARD PROBLEM]" --model opus --output-format json

# Gemini 3 Pro (already the default, 1M context)
gemini "[HARD PROBLEM]" -m gemini-3-pro-preview -o json
```

### Fast Consultations

When speed matters more than depth:

```bash
claude -p "[QUERY]" --model haiku --output-format json
gemini "[QUERY]" -m gemini-3-flash-preview -o json
```

### Parallel Research

Run all braintrust members simultaneously:

```bash
# Launch all three in parallel
claude -p "$QUERY" --model sonnet --output-format json > /tmp/claude.json &
gemini "$QUERY" -m gemini-3-pro-preview -o json > /tmp/gemini.json &
codex exec --json "$QUERY" > /tmp/codex.json &
wait

# Collect results
echo "=== Claude ===" && jq -r '.result' /tmp/claude.json
echo "=== Gemini ===" && jq -r '.response' /tmp/gemini.json
echo "=== Codex ===" && grep agent_message /tmp/codex.json | jq -r '.item.text'
```

## Model Reference

> **Note:** Model names and flags evolve as CLIs update. Verify current model names with `claude --help`, `gemini --help`, or `codex --help` if commands fail. The examples below reflect typical patterns.

### Claude Code

| Model | Context | Use Case |
|-------|---------|----------|
| **Sonnet 4.5** | 200K (1M beta) | Default - balanced performance, large context available |
| **Opus 4.5** | 200K | Hardest reasoning problems |
| **Haiku 4.5** | 200K | Speed, cost efficiency |

### Gemini (Gemini 3 Only)

| Model | Context | Use Case |
|-------|---------|----------|
| **Gemini 3 Pro** | 1M | Default - maximum reasoning |
| **Gemini 3 Flash** | 1M | Speed - still very capable |

### Codex

| Model | Context | Availability |
|-------|---------|--------------|
| **GPT-5-Codex** | 400K | Default (ChatGPT auth) |
| **GPT-5.2-Codex** | 400K | API key auth only |

## Output Parsing

### Claude JSON Output
```json
{
  "type": "result",
  "result": "response text here",
  "session_id": "uuid",
  "total_cost_usd": 0.05
}
```
Parse with: `jq -r '.result'`

### Gemini JSON Output
```json
{
  "session_id": "uuid",
  "response": "response text here",
  "stats": { "models": {...}, "tokens": {...} }
}
```
Parse with: `jq -r '.response'`

### Codex JSONL Output (streaming)
```json
{"type":"item.completed","item":{"type":"agent_message","text":"response here"}}
```
Parse with: `jq -rs 'map(select(.item.type? == "agent_message")) | last | .item.text'`

## Common Use Cases

### 1. Design & Frontend Review

```bash
# Have Gemini review your React components for design quality
gemini "@src/components/ Review these components for:
1. Design consistency (spacing, colors, typography)
2. Accessibility compliance
3. Responsive design patterns
4. Component API design (props, composition)
What's working well? What needs improvement?" -m gemini-3-pro-preview -o json | jq -r '.response'

# Generate pixel-perfect code from a design mockup
gemini "@mockup.png Implement this design as a React component with Tailwind CSS. Match the exact spacing, colors, and typography." -m gemini-3-pro-preview -o json | jq -r '.response'
```

### 2. Architecture Review

```bash
# Get Gemini's take on overall architecture (uses 1M context)
gemini "@src/ Analyze the architecture. What are the main components and how do they interact? Identify any architectural debt or inconsistencies." -m gemini-3-pro-preview -o json | jq -r '.response'
```

### 3. Cross-Model Code Review

```bash
# After implementing with Claude, get Gemini's review as a peer
gemini "@src/features/auth/ Review these changes as if you're a senior developer on the team. Look for:
- Bugs or logic errors
- Security issues
- Performance concerns
- Patterns inconsistent with the rest of the codebase
- Missed edge cases" -m gemini-3-pro-preview -o json | jq -r '.response'
```

### 4. Security Audit

```bash
# Parallel security review across all three models
AUDIT_PROMPT="Review this codebase for security vulnerabilities:
1. Authentication/authorization flaws
2. SQL injection or NoSQL injection
3. XSS vulnerabilities
4. CSRF protection
5. Secrets in code
6. Rate limiting gaps"

claude -p "$AUDIT_PROMPT $(find src -name '*.ts' -exec cat {} \;)" --model sonnet --output-format json > /tmp/claude-security.json &
gemini "@src/ $AUDIT_PROMPT" -m gemini-3-pro-preview -o json > /tmp/gemini-security.json &
codex exec --json "$AUDIT_PROMPT" > /tmp/codex-security.json &
wait

# Compare findings
echo "=== Claude ===" && jq -r '.result' /tmp/claude-security.json
echo "=== Gemini ===" && jq -r '.response' /tmp/gemini-security.json
echo "=== Codex ===" && grep agent_message /tmp/codex-security.json | jq -r '.item.text'
```

### 5. System-Wide Bug Investigation

```bash
# When bugs span multiple files, use Gemini's full-context view
BUG="Users report intermittent 500 errors on /api/checkout. Logs show connection timeout."
gemini "@src/ Debug this system-wide issue: $BUG

Trace the request flow from entry point to database. Identify:
1. All code paths involved
2. Connection pooling configuration
3. Timeout settings
4. Retry logic (or lack thereof)
5. Error handling gaps" -m gemini-3-pro-preview -o json | jq -r '.response'
```

### 6. Framework Migration Planning

```bash
# Get side-by-side comparison for migration
gemini "@src/ We're considering migrating from React class components to hooks. Analyze:
1. Current patterns used
2. Migration complexity per component
3. Suggested migration order
4. Potential breaking changes
5. Testing strategy" -m gemini-3-pro-preview -o json | jq -r '.response'
```

### 7. Parallel Research

```bash
# Query all three for diverse perspectives
TOPIC="best practices for implementing rate limiting in Node.js APIs"
claude -p "Research: $TOPIC" --model sonnet --output-format json > /tmp/claude.json &
gemini "Research: $TOPIC" -m gemini-3-pro-preview -o json > /tmp/gemini.json &
codex exec --json "Research: $TOPIC" > /tmp/codex.json &
wait

# Synthesize findings
echo "=== Claude ===" && jq -r '.result' /tmp/claude.json
echo "=== Gemini ===" && jq -r '.response' /tmp/gemini.json
echo "=== Codex ===" && grep agent_message /tmp/codex.json | jq -r '.item.text'
```

## Key Flags Reference

### Claude Code
| Flag | Purpose |
|------|---------|
| `-p, --print` | Headless mode |
| `--model` | Model selection (haiku/sonnet/opus) |
| `--output-format` | text/json/stream-json |
| `--max-turns` | Limit agentic turns |

### Gemini
| Flag | Purpose |
|------|---------|
| Positional | Query (triggers headless mode) |
| `-m, --model` | Model selection |
| `-o, --output-format` | text/json/stream-json |
| `@path` | Include file/directory in context |
| `--yolo` | Auto-approve actions |

### Codex
| Flag | Purpose |
|------|---------|
| `exec` | Non-interactive subcommand |
| `--json` | JSONL output |
| `-m, --model` | Model (API key auth only) |
| `--full-auto` | Low-friction automation |

## Tips

1. **Use Gemini for design & frontend** - Leads WebDev Arena, 35% higher accuracy on UI challenges
2. **Use Gemini for large context** - 1M tokens native vs 200K for Claude/Codex; can analyze 40K+ lines holistically
3. **Cross-model review catches bugs** - When a model writes code, it's blind to its own mistakes; different models spot issues instantly
4. **Use explicit models** - Headless defaults auto-route to weaker models; always specify `--model sonnet` or `-m gemini-3-pro-preview`
5. **Parse JSON output** - Structured output enables scripting, automation, and synthesis
6. **Parallel is fast** - Run all three simultaneously for 3x speed and diverse perspectives
7. **Different models, different blind spots** - Each AI has different training; combined approaches outperform individuals

## Further Reading

- [Claude + Gemini Workflow: When AIs Start Gossiping About Your Code](https://byjos.dev/claude-gemini-workflow/)
- [Claude Code Bridge: Multi-AI Collaboration](https://github.com/bfly123/claude_code_bridge)
- [Using Gemini CLI for Large Codebase Analysis](https://gist.github.com/steipete/20ed650822f1ac835144bfd328c872b7)
- [Gemini CLI Code Review and Security Analysis](https://codelabs.developers.google.com/gemini-cli-code-analysis)
