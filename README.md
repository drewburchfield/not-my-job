<div align="center">

# not-my-job

**Agentic coding tool plugins for tasks you'd rather not do yourself.**

*Someone has to audit your subscriptions, tell you when you're wrong, and deal with LinkedIn. It's not going to be you!*

![License](https://img.shields.io/badge/license-MIT-blue)

</div>

<br>

| | Plugin | What it does |
|:--:|--------|--------------|
| 💸 | [**subscription-cleanse**](#subscription-cleanse) | Find forgotten subscriptions bleeding your bank account |
| 🧠 | [**braintrust**](#braintrust) | Delegate work to other AI CLIs and get second opinions |
| 💼 | [**linkedin-message-triage**](#linkedin-message-triage) | Systematic inbox review and response drafting |
| 📄 | [**markdown-to-confluence**](#markdown-to-confluence) | Convert Markdown to Confluence Storage Format |
| 🏢 | [**cre-property-research**](#cre-property-research) | Commercial real estate research and market analysis |
| 🔐 | [**1password-management**](#1password-management) | Proper syntax for 1Password CLI |
| 📝 | [**readme-craft**](#readme-craft) | Write clean, human-sounding README files |
| 🎫 | [**helpscout-navigator**](#helpscout-navigator) | HelpScout search guidance with bundled MCP server |
| 🏗 | [**project-bootstrap**](#project-bootstrap) | Auto-detect language, set up quality tooling, run code reviews |

<br>

## Install

```bash
claude plugins marketplace add drewburchfield/not-my-job
```

```bash
claude plugins install subscription-cleanse@not-my-job
claude plugins install braintrust@not-my-job
```

<br>

<p align="center">· · ·</p>

## Plugins

### 💸 subscription-cleanse

Comprehensive subscription audit using bank CSV analysis and email reconnaissance.

| Feature | Description |
|---------|-------------|
| Bank CSV parsing | Apple Card, Chase, Mint, Capital One, etc. |
| Transaction decoding | Privacy.com, PayPal, Square, Google, Apple |
| Email recon | Gmail MCP integration |
| Output | Interactive HTML audit report |

<p align="center">―</p>

### 🧠 braintrust

Inspired by [this Reddit post](https://www.reddit.com/r/ChatGPTCoding/comments/1lm3fxq/gemini_cli_is_awesome_but_only_when_you_make/) and expanded with community learnings and real-world usage to work from any harness.

| Use Case | Why |
|----------|-----|
| Offload grunt work | Have Gemini chew through your entire codebase (1M context) while you stay focused |
| Second opinions | Models are blind to their own bugs; fresh weights spot issues instantly |
| Design review | Gemini 3 dominates WebDev Arena — let it critique your UI before you ship |
| Validate direction | Sanity check architecture decisions before you're 2000 lines deep |
| Parallel research | Query all three simultaneously, synthesize the best answer |

**Requires:** Claude Code CLI, Gemini CLI, Codex CLI

<p align="center">―</p>

### 💼 linkedin-message-triage

Systematic LinkedIn inbox review and response drafting.

- Filter real connections from solicitations
- Identify messages needing responses
- Draft personalized replies with career context
- Handle delayed response acknowledgments

**Requires:** Playwright MCP

<p align="center">―</p>

### 📄 markdown-to-confluence

Convert Markdown documents to Confluence Storage Format (XHTML-based XML).

- Standard markdown syntax
- Code blocks with syntax highlighting
- Tables, lists, links, images
- Bundled Python conversion script

<p align="center">―</p>

### 🏢 cre-property-research

Institutional-grade commercial real estate research and market analysis.

- Multi-phase research framework
- Market rate comparisons with source citations
- Tenant prospecting strategies by property type
- Competitive intelligence gathering

**Property types:** Industrial · Flex · Office · Retail · Multifamily

<p align="center">―</p>

### 🔐 1password-management

Proper syntax and best practices for 1Password CLI (`op`).

- Correct `op item create` syntax
- Complete field type reference
- Category selection guide
- Security best practices

<p align="center">―</p>

### 📝 readme-craft

Write READMEs that are visually pleasing, appropriately scoped, and sound like a human wrote them.

- Structure templates (minimal, standard, collection)
- Visual polish techniques without overkill
- Voice and tone guidance to avoid AI-generated vibes
- Badge best practices

<p align="center">―</p>

### 🎫 helpscout-navigator

Guidance for correctly using HelpScout MCP tools. Bundles the MCP server — auto-starts when plugin is enabled.

- Decision tree for choosing the right search tool
- Correct sequencing (always lookup inbox IDs first)
- Prevents the "active-only" search trap
- Complete parameter reference for all 9 tools

**Requires:** `HELPSCOUT_APP_ID` and `HELPSCOUT_APP_SECRET` environment variables

<p align="center">―</p>

### 🏗 project-bootstrap

One-time setup for consistent quality gates across your projects.

- Auto-detects language (TypeScript, Python, Go)
- Installs and configures linting, formatting, and type checking
- Stop hook enforces quality gates on every Claude session
- `/quality-review` runs a PR-style code review without needing a PR

**Languages:** TypeScript (ESLint + Prettier) · Python (ruff + pyright) · Go (built-in tooling)

<br>

<p align="center">· · ·</p>

## Configuration

```json
{
  "enabledPlugins": {
    "subscription-cleanse@not-my-job": true,
    "braintrust@not-my-job": true
  }
}
```

<sup>`.claude/settings.json`</sup>

<br>

## License

MIT
