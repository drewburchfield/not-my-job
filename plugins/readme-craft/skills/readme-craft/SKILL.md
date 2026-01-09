---
name: readme-craft
description: >
  Write clean, human-sounding README files for personal and open source projects.
  Use when creating or improving a README, especially for smaller projects that don't need
  enterprise-grade documentation. Focuses on visual polish without overkill, and authentic
  voice without AI-generated vibes.
---

# README Craft

Write READMEs that are visually pleasing, appropriately scoped, and sound like a human wrote them.

## When to Use This Skill

- Creating a new README for a personal or open source project
- Improving an existing README that feels bland or cluttered
- Reviewing a README before publishing/open-sourcing
- When you want polish without enterprise bloat

## Core Principles

| Principle | What It Means |
|-----------|---------------|
| **Less is more** | Skip sections you don't need. Personal projects don't need Roadmaps, Contributing guides, or Code of Conduct unless you want contributions |
| **Visual breathing room** | White space, horizontal rules, and `<br>` tags prevent wall-of-text feel |
| **Meaningful badges only** | 1-3 badges that convey useful info. Skip vanity metrics |
| **Voice over emojis** | Personality comes from *how you write*, not decorating headers |
| **Show don't tell** | A GIF or screenshot beats paragraphs of explanation |

## Structure Templates

### Minimum Viable (Single Tool/Script)

```markdown
# Project Name

One-line description of what this does.

## Install

\`\`\`bash
install command
\`\`\`

## Usage

\`\`\`bash
usage example
\`\`\`

## License

MIT
```

### Standard (Library/Tool)

```markdown
# Project Name

**Tagline that captures the vibe.**

## Install

\`\`\`bash
install command
\`\`\`

## Usage

\`\`\`bash
basic usage
\`\`\`

Brief explanation if needed.

## Configuration

Optional section if there are options.

## License

MIT
```

### Collection (Multiple Plugins/Tools)

```html
<div align="center">

# collection-name

**Tagline that captures the vibe.**

![License](https://img.shields.io/badge/license-MIT-blue)

</div>

<br>

| | Item | What it does |
|:--:|------|--------------|
| 💸 | [**item-one**](#item-one) | One sentence |
| 🧠 | [**item-two**](#item-two) | One sentence |

<br>

## Install

\`\`\`bash
install commands
\`\`\`

<br>

<p align="center">· · ·</p>

## Items

### 💸 item-one

Description. Table for features if needed.

**Requires:** Dependencies

<p align="center">―</p>

### 🧠 item-two

Same pattern...

<br>

<p align="center">· · ·</p>

## Configuration

\`\`\`json
{ "example": "config" }
\`\`\`

## License

MIT
```

## Visual Polish Techniques

### Tasteful Elements

| Element | When to Use |
|---------|-------------|
| Centered hero | Title + tagline + badge centered for intentional feel |
| Icon column in tables | Emojis in dedicated first column, not scattered in headers |
| Section dividers | `· · ·` for major breaks, `―` between items |
| Tables | Structured data, feature lists, comparisons |
| `<br>` tags | Add breathing room between sections |
| Blockquotes | Taglines, callouts, quotes |
| `<sup>` | File path hints, footnotes |
| Code blocks | Installation, usage, config examples |

### Centered Hero Pattern

Makes the opening feel designed rather than default:

```html
<div align="center">

# project-name

**Tagline that captures the vibe.**

![License](https://img.shields.io/badge/license-MIT-blue)

</div>
```

### Icon Column Pattern

Keeps emojis structured instead of scattered:

```markdown
| | Plugin | What it does |
|:--:|--------|--------------|
| 💸 | **plugin-one** | Description |
| 🧠 | **plugin-two** | Description |
```

The `:--:` centers the icon column.

**Visual continuity:** For collection READMEs, repeat the same icon in the detail section header (e.g., `### 💸 plugin-one`). This creates a clear visual link between the summary table and the detailed sections.

### Section Dividers

Add rhythm without clutter:

```html
<!-- Major section break -->
<p align="center">· · ·</p>

<!-- Between items in a list -->
<p align="center">―</p>
```

### Skip These (Overkill)

- Badge walls (more than 3-4 badges)
- ASCII art banners
- Animated header GIFs (unless demo is crucial)
- Multiple emojis per line
- Decorative emojis on headers (exception: thoughtful icons on collection items that match their summary table)
- Contributor avatar grids (unless large project)
- Table of Contents (unless 500+ lines)
- "Welcome to..." greetings

## Voice and Tone

### AI-Generated Vibes (Avoid)

| Pattern | Problem |
|---------|---------|
| "This project aims to provide a comprehensive solution for..." | Corporate fluff |
| "Please note that..." | Unnecessary hedging |
| "Welcome to ProjectName!" | Skip greetings |
| "We" and "our" for solo projects | Use "I" or imperative voice |
| Every section filled in | Only include what's useful |
| Generic descriptions | Be specific and opinionated |

### Human Vibes (Do This)

| Instead of | Write |
|------------|-------|
| "A tool for managing subscriptions" | "Find forgotten subscriptions bleeding your bank account" |
| "Please run the following command" | "Run:" |
| "This feature allows users to..." | "You can..." or just describe it |
| "We believe in..." | Skip the manifesto |
| "At this time..." | Just say what is |

### Google's Guidance

> *"Be human, let your personality show, and be memorable. But remember the primary purpose is to provide information to someone who may be in a hurry."*

Key points:
- Conversational but not colloquial
- Sound like a knowledgeable friend
- Read it aloud - does it flow?
- Skip "please" in instructions
- Avoid buzzwords and jargon
- No exclamation marks (except rare moments)

## Badges

### Worth Including

| Badge | Why |
|-------|-----|
| License | People look for this |
| Version/Release | If you version releases |
| Platform/Runtime | If not obvious (e.g., Node version) |

### Skip Unless Meaningful

| Badge | When to Skip |
|-------|--------------|
| CI/CD status | Unless stability is a key selling point |
| Code coverage | Unless quality is the project's purpose |
| Stars/Forks | GitHub already shows these |
| "Made with love" | Adds nothing |

### Badge Syntax

```markdown
![License](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-1.0.0-green)
```

Use [Shields.io](https://shields.io/) for generation.

## Section-by-Section Guidance

### Project Title

- Clear, memorable name
- Can include an emoji/icon if it fits
- Don't repeat the name in a subtitle

### Tagline

- One line, captures the vibe
- Can be bold, can be a blockquote
- Personality lives here

**Good:** `**Claude Code plugins for tasks you'd rather not do yourself.**`

**Bad:** `A collection of plugins for the Claude Code CLI.`

### Description

- What it does (concrete, specific)
- Who it's for (if not obvious)
- Skip "why I built this" unless it's interesting

### Install

- Copy-pasteable commands
- Minimal explanation
- Prerequisites only if unusual

### Usage

- Start with the most common case
- Show expected output if helpful
- Keep examples real, not `foo`/`bar`

### Configuration

- Only if there are options
- Show real config, not every possible option
- Use comments sparingly

### License

- Just the name and link
- No explanation needed

## Checklist Before Publishing

- [ ] Can someone understand what it does in 10 seconds?
- [ ] Are install commands copy-pasteable?
- [ ] Is there at least one usage example?
- [ ] Did you remove sections you don't need?
- [ ] Does it sound like you wrote it, not a template?
- [ ] Are badges meaningful or just decoration?
- [ ] Is there breathing room between sections?

## Sources

This skill synthesizes guidance from:

- [awesome-readme](https://github.com/matiassingers/awesome-readme) - Curated examples
- [The Good Docs Project](https://www.thegooddocsproject.dev/template/readme) - Section guidance
- [Make a README](https://www.makeareadme.com/) - Structure principles
- [Google Voice & Tone](https://developers.google.com/style/tone) - Writing style
- [Shields.io Best Practices](https://daily.dev/blog/readme-badges-github-best-practices) - Badge guidance
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) - Popular template
