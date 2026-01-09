# not-my-job

A collection of Claude Code plugins for tasks you'd rather not do yourself.

## Installation

Add the marketplace:
```bash
claude plugins marketplace add drewburchfield/not-my-job
```

Then install the plugins you want:
```bash
claude plugins install 1password-management@not-my-job
claude plugins install subscription-cleanse@not-my-job
```

## Available Plugins

### 1password-management
Proper syntax and best practices for managing credentials with 1Password CLI (`op`).

- Correct `op item create` syntax (fixes common bracket quoting issues)
- Complete field type reference (password, text, url, email, date, etc.)
- Category selection guide (API Credential, Login, Secure Note)
- Security best practices

### cre-property-research
Institutional-grade commercial real estate property research and market analysis.

- Multi-phase research framework (property, market, location, tenants)
- Market rate comparisons with source citations
- Tenant prospecting strategies by property type
- Competitive intelligence gathering

**Property types:** Industrial, flex, office, retail, multifamily

### linkedin-message-triage
Systematic LinkedIn inbox review and response drafting.

- Filter real connections from solicitations/InMail
- Identify messages needing responses
- Draft personalized replies with career context
- Handle delayed response acknowledgments

**Requires:** Playwright MCP for browser automation

### markdown-to-confluence
Convert Markdown documents to Confluence Storage Format (XHTML-based XML).

- Standard markdown syntax support
- Code blocks with syntax highlighting
- Tables, lists, links, images
- Bundled Python conversion script

### subscription-cleanse
Comprehensive subscription audit using bank CSV analysis and email reconnaissance.

- Bank CSV parsing (Apple Card, Chase, Mint, Capital One, etc.)
- Privacy.com, PayPal, Square, Google, Apple transaction decoding
- Email reconnaissance via Gmail MCP
- Interactive HTML audit report generation

### braintrust
Orchestrate other AI CLIs (Gemini, Codex, Claude Code) for second opinions, codebase analysis, and parallel research.

- **Design & frontend review** - Gemini 3 leads WebDev Arena, 35% higher accuracy on UI tasks
- **Architecture review** - Gemini's 1M context analyzes 40K+ lines holistically
- **Cross-model code review** - Different training catches different blind spots
- **Security audit** - Parallel review across all three catches more vulnerabilities
- **System-wide debugging** - Full-codebase context for complex bugs
- **Parallel research** - 3x speed with diverse perspectives

**Requires:** Claude Code CLI, Gemini CLI, Codex CLI installed and authenticated

---

## Repository Structure

```
claude-skills/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── 1password-management/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/
│   │   └── skills/
│   ├── braintrust/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/
│   │   └── skills/
│   ├── cre-property-research/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/
│   │   └── skills/
│   ├── linkedin-message-triage/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/
│   │   └── skills/
│   ├── markdown-to-confluence/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/
│   │   └── skills/
│   └── subscription-cleanse/
│       ├── .claude-plugin/plugin.json
│       ├── commands/
│       └── skills/
└── README.md
```

## Per-Project Configuration

Disable plugins you don't need in a project's `.claude/settings.json`:
```json
{
  "enabledPlugins": {
    "subscription-cleanse@not-my-job": true,
    "cre-property-research@not-my-job": false
  }
}
```

## License

MIT License
