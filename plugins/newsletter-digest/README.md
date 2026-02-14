# Newsletter Digest Plugin

**One-at-a-time newsletter review workflow for product managers and AI practitioners.**

This plugin automates the tedious parts of newsletter triage: fetching from Gmail, categorizing by topic, and presenting an interactive browser UI where you make quick save/archive decisions. Then it executes your decisions: creating Obsidian notes for valuable content and archiving the rest from your inbox.

## What This Plugin Is For

**Target newsletters:**
- **Product Management**: Lenny's Newsletter, Product Tapas, PM frameworks, growth strategies
- **AI Strategy**: Industry analysis, AGI timelines, market dynamics, strategic implications
- **AI Tools**: Coding agents (Claude, Cursor), development workflows, automation tools
- **Leadership & Life**: Professional development, emotional intelligence, team culture
- **Community**: Slack discussions, curated threads, collective wisdom

**If you subscribe to these types of newsletters and want to:**
- ✅ Process weekly batches efficiently (15-20 minutes)
- ✅ Save valuable insights to Obsidian for later reference
- ✅ Archive the rest to keep inbox clean
- ✅ Never miss important content while avoiding newsletter overload

**This plugin is NOT for:**
- ❌ News briefings or daily digests (too high-volume)
- ❌ Transactional emails (receipts, notifications)
- ❌ Marketing/promotional emails (different workflow)
- ❌ General newsletters outside product/AI domains (categorization won't work well)

## How It Works

```
User runs: /newsletter-digest

1. Fetches newsletters from Gmail (last 7 days)
2. Auto-categorizes by topic (AI Tools, Strategy, Product, etc.)
3. Generates interactive HTML digest
4. User reviews one-at-a-time in browser (keyboard shortcuts!)
5. Downloads decisions file to ~/Downloads/
6. Creates Obsidian notes for saved items
7. Archives dismissed items from inbox
8. Shows summary of what happened
```

## Installation

### Prerequisites

**Required:**
1. **gog CLI** - Gmail access
   ```bash
   brew install steipete/tap/gogcli
   gog auth add your@gmail.com --services gmail
   ```

2. **jq** - JSON processing
   ```bash
   brew install jq
   ```

**Optional:**
3. **Note storage** - Configure in `newsletter-digest.local.md`:
   - **Local directory** (default): Saves to `./newsletter-notes/`
   - **Obsidian MCP Server**: If you have Obsidian MCP configured
   - **Obsidian filesystem**: If you have a local vault folder

   See [Configuration](#configuration) section below.

### Plugin Installation

1. This plugin is part of the `not-my-job` repository
2. Make sure it's in the Claude Code plugin path
3. **Configure your preferences** (recommended):
   ```bash
   cd plugins/newsletter-digest/
   cp newsletter-digest.local.md.example newsletter-digest.local.md
   # Edit newsletter-digest.local.md with your preferences
   ```
4. Restart Claude Code or reload plugins
5. Run `/newsletter-digest` to start

## Configuration

**First time setup:**

```bash
cp newsletter-digest.local.md.example newsletter-digest.local.md
```

Then edit `newsletter-digest.local.md`:

### Option 1: Local Directory (Default)
**Use if:** You don't use Obsidian or want simple markdown files

```yaml
obsidian_enabled: false
obsidian_type: "none"
markdown_output_dir: "./newsletter-notes"
```

Notes saved to `./newsletter-notes/` in your working directory.

### Option 2: Obsidian MCP Server
**Use if:** You have Obsidian MCP server configured

```yaml
obsidian_enabled: true
obsidian_type: "mcp"
obsidian_mcp_server: "obsidian"  # Your MCP server name
```

Notes created via MCP server tools (check your MCP configuration for server name).

### Option 3: Obsidian Filesystem
**Use if:** You have a local Obsidian vault folder

```yaml
obsidian_enabled: true
obsidian_type: "filesystem"
obsidian_vault_path: "~/Documents/MyVault/Inbox"
```

Notes written directly to vault folder.

## Usage

### Basic Workflow

```bash
/newsletter-digest
```

That's it! The plugin handles:
- Fetching from Gmail
- Categorization
- HTML generation
- Browser opening

**Then you:**
1. Review newsletters one-at-a-time
2. Press **S** to save, **A** to archive, **Space** to skip
3. Click "Save Decisions to File" when done
4. Confirm execution

### Keyboard Shortcuts

In the browser UI:
- **S** - Save to Obsidian (mark as valuable)
- **A** - Archive from inbox (dismiss)
- **Space** or **→** - Skip (no action)
- **←** - Go back one newsletter
- Decisions persist in localStorage (survives refresh)

### What Gets Created

**For saved newsletters:**
- Markdown note with frontmatter (title, source, date, threadId, category, tags)
- Content: summary, snippet, Gmail link
- Format: `Newsletter - YYYY-MM-DD - Title.md`
- Location: **Depends on your configuration**
  - Local: `./newsletter-notes/`
  - MCP: Created via Obsidian MCP server
  - Filesystem: Your vault path (e.g., `~/Documents/Vault/Inbox/`)

**For archived newsletters:**
- Removed from Gmail inbox (but not deleted)
- Can still search/access via Gmail
- Keeps inbox clean

**Decisions file:**
- Downloaded to `~/Downloads/newsletter-decisions.md`
- Lists all save/archive decisions with threadIds
- Audit trail for what was processed

## Customization

**All customization via `newsletter-digest.local.md` configuration file!**

### Adjust Timeframe

```yaml
# In newsletter-digest.local.md
search_timeframe: "14d"  # Options: 7d, 14d, 30d
```

### Customize Newsletter Sources

```yaml
# In newsletter-digest.local.md
search_query: |
  in:inbox (
    from:your-newsletter-source.com OR
    from:another-sender@substack.com OR
    label:Your-Custom-Label
  ) newer_than:{timeframe}
```

### Change Note Storage Location

```yaml
# Local directory
obsidian_enabled: false
markdown_output_dir: "~/Documents/NewsletterNotes"

# Or Obsidian MCP server
obsidian_enabled: true
obsidian_type: "mcp"
obsidian_mcp_server: "your-mcp-server-name"

# Or Obsidian filesystem
obsidian_enabled: true
obsidian_type: "filesystem"
obsidian_vault_path: "~/Documents/Vault/Inbox"
```

### Add Custom Categories

1. Edit `skills/newsletter-digest/references/category-patterns.md`
2. Add new category section with sender/subject patterns
3. Re-run categorization

Example:
```markdown
## Your New Category

**From patterns:**
- sender@example.com

**Subject patterns:**
- keyword1, keyword2, keyword3

**Category description:** What this category covers
```

## Troubleshooting

### "gog command not found"

```bash
brew install steipete/tap/gogcli
gog auth add your@gmail.com --services gmail
```

### "gog not authenticated"

```bash
gog auth list  # Check status
gog auth add your@gmail.com --services gmail --force-consent
```

### "Fetched 0 newsletters"

**Possible causes:**
1. No newsletters in inbox (already processed?)
2. Timeframe too short (try 14d or 30d)
3. Search query doesn't match your newsletters

**Debug:**
```bash
# Test search query manually
gog gmail search 'in:inbox from:substack.com newer_than:7d' --max 10
```

### "Where are my saved notes?"

Check your configuration in `newsletter-digest.local.md`:

```bash
# If using local directory (default)
ls ./newsletter-notes/

# If using Obsidian MCP server
# Check via MCP server tools

# If using Obsidian filesystem
ls ~/path/to/your/vault/Inbox/
```

If you haven't configured anything, notes save to `./newsletter-notes/` by default.

### "Too many uncategorized newsletters"

Edit `skills/newsletter-digest/references/category-patterns.md` to add patterns for your newsletters.

Check current categories:
```bash
cd skills/newsletter-digest/scripts
./categorize-newsletters.sh newsletters-raw.json newsletters-categorized.json
# See category breakdown in output
```

## Examples

### Weekly Review

```bash
# Every Monday morning
/newsletter-digest

# Review 20-30 newsletters in 15 minutes
# Save 5-8 valuable ones to Obsidian
# Archive the rest
# Inbox: clean ✓
```

### Custom Timeframe

```bash
# After vacation - catch up on 2 weeks
# Edit fetch-newsletters.sh: TIMEFRAME="14d"
/newsletter-digest
```

### Batch Processing

For very large batches (50+ newsletters), the plugin creates a working file to track progress through all phases.

## Architecture

```
newsletter-digest/
├── .claude-plugin/
│   └── plugin.json                    # Plugin metadata
├── commands/
│   └── newsletter-digest.md           # /newsletter-digest command
├── skills/
│   └── newsletter-digest/
│       ├── SKILL.md                   # Main workflow orchestration
│       ├── scripts/
│       │   ├── fetch-newsletters.sh   # gog CLI wrapper
│       │   ├── categorize-newsletters.sh  # Pattern matching
│       │   ├── generate-html.sh       # Template population
│       │   └── template.html          # Interactive UI
│       └── references/
│           ├── category-patterns.md   # Categorization rules
│           └── known-newsletters.md   # Newsletter database
├── hooks/
│   ├── hooks.json                     # Hook configuration
│   └── session-start.sh               # Verify gog CLI
└── README.md                          # This file
```

## Design Philosophy

**Key principles:**
1. **Script-driven extraction**: Never improvise with raw CLI commands
2. **Grounding**: Always cite threadIds, never hallucate content
3. **Working files**: Track progress for large batches
4. **Reference files**: Externalize rules for easy customization
5. **Graceful degradation**: Fallbacks when optional dependencies missing
6. **User control**: User makes decisions, plugin executes

## Development

### Testing Scripts Individually

```bash
cd skills/newsletter-digest/scripts/

# Test fetch
./fetch-newsletters.sh 7d test-raw.json

# Test categorize
./categorize-newsletters.sh test-raw.json test-cat.json

# Test HTML generation
./generate-html.sh test-cat.json test-digest.html
open test-digest.html
```

### Adding New Newsletter Sources

1. Add to `known-newsletters.md` for documentation
2. Update query in `fetch-newsletters.sh`
3. Add patterns to `category-patterns.md` if needed
4. Test with real data

### Debugging Categorization

```bash
# See how newsletters are being categorized
./categorize-newsletters.sh newsletters-raw.json newsletters-categorized.json

# Check category breakdown in output
# Adjust patterns in references/category-patterns.md as needed
```

## Best Practices

1. **Run weekly**: Consistent cadence prevents inbox buildup
2. **Batch review**: Set aside 15-20 minutes for focused triage
3. **Trust your gut**: Skip quickly, save sparingly
4. **Archive aggressively**: If unsure, archive (can always search later)
5. **Review saved notes**: Periodically review Obsidian notes for patterns
6. **Update patterns**: As you subscribe to new newsletters, update category patterns

## Limitations

- **Gmail only**: Requires gog CLI with Gmail access
- **Pattern-based categorization**: Works best for product/AI newsletters
- **English content**: Categorization patterns optimized for English
- **Manual execution**: User must confirm actions (by design for safety)

## Future Enhancements

Potential improvements (not yet implemented):
- [ ] Support for multiple inboxes/Gmail accounts
- [ ] AI-powered summarization (not just snippets)
- [ ] Newsletter-specific extractors (Lenny's format, etc.)
- [ ] Slack integration (post saved newsletters to channel)
- [ ] Analytics (track what you save over time)
- [ ] Mobile-friendly HTML UI

## License

MIT License - See repository root for details

## Credits

Built with:
- [gog CLI](https://github.com/steipete/gogcli) - Google Workspace automation
- [jq](https://jqlang.github.io/jq/) - JSON processing
- Vanilla HTML/CSS/JS - No dependencies for browser UI

Inspired by:
- Superhuman's inbox zero philosophy
- Readwise's knowledge capture workflow
- The need for sustainable newsletter consumption habits

---

**Questions or issues?** Open an issue in the not-my-job repository.
