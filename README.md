# 🚫 not-my-job

**Claude Code plugins for tasks you'd rather not do yourself.**

<br>

## ⭐ Featured

| Plugin | What it does |
|--------|--------------|
| [**subscription-cleanse**](#-subscription-cleanse) | Find forgotten subscriptions bleeding your bank account |
| [**braintrust**](#-braintrust) | Delegate work to other AI CLIs and get second opinions |

<br>

## Installation

```bash
claude plugins marketplace add drewburchfield/not-my-job
```

```bash
claude plugins install subscription-cleanse@not-my-job
claude plugins install braintrust@not-my-job
```

<br>

---

## 💸 subscription-cleanse

Comprehensive subscription audit using bank CSV analysis and email reconnaissance.

| Feature | Description |
|---------|-------------|
| Bank CSV parsing | Apple Card, Chase, Mint, Capital One, etc. |
| Transaction decoding | Privacy.com, PayPal, Square, Google, Apple |
| Email recon | Gmail MCP integration |
| Output | Interactive HTML audit report |

---

## 🧠 braintrust

> *Get the best of both worlds: your primary model doesn't waste context, and the others don't waste your time.*

Inspired by [this Reddit post](https://www.reddit.com/r/ChatGPTCoding/comments/1lm3fxq/gemini_cli_is_awesome_but_only_when_you_make/) (1.2K upvotes) and expanded with community learnings and real-world usage to work from any harness.

| Use Case | Why |
|----------|-----|
| **Offload the grunt work** | Have Gemini chew through your entire codebase (1M context) while you stay focused |
| **Get a second opinion** | Models are blind to their own bugs; a fresh set of weights spots issues instantly |
| **Design review** | Gemini 3 dominates WebDev Arena — let it critique your UI before you ship |
| **Validate your direction** | Sanity check architecture decisions before you're 2000 lines deep |
| **Parallel research** | Query all three simultaneously, synthesize the best answer |

**Requires:** Claude Code CLI, Gemini CLI, Codex CLI

---

## 💼 linkedin-message-triage

Systematic LinkedIn inbox review and response drafting.

- Filter real connections from solicitations/InMail
- Identify messages needing responses
- Draft personalized replies with career context
- Handle delayed response acknowledgments

**Requires:** Playwright MCP

---

## 📄 markdown-to-confluence

Convert Markdown documents to Confluence Storage Format (XHTML-based XML).

- Standard markdown syntax support
- Code blocks with syntax highlighting
- Tables, lists, links, images
- Bundled Python conversion script

---

## 🏢 cre-property-research

Institutional-grade commercial real estate property research and market analysis.

- Multi-phase research framework (property, market, location, tenants)
- Market rate comparisons with source citations
- Tenant prospecting strategies by property type
- Competitive intelligence gathering

**Property types:** Industrial · Flex · Office · Retail · Multifamily

---

## 🔐 1password-management

Proper syntax and best practices for managing credentials with 1Password CLI (`op`).

- Correct `op item create` syntax (fixes common bracket quoting issues)
- Complete field type reference (password, text, url, email, date, etc.)
- Category selection guide (API Credential, Login, Secure Note)
- Security best practices

---

<br>

## Configuration

```json
{
  "enabledPlugins": {
    "subscription-cleanse@not-my-job": true,
    "braintrust@not-my-job": true,
    "linkedin-message-triage@not-my-job": false
  }
}
```

<sup>`.claude/settings.json`</sup>

<br>

## License

MIT
