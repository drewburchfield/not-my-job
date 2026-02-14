# Known Newsletters Database

This file maintains a list of recognized newsletters and their typical categorization. This helps improve categorization accuracy.

## AI Tools & Workflows

- **Lenny's How I AI** (`lenny+how-i-ai@substack.com`)
  - Focus: Practical AI workflows, tool usage, coding agents

- **Product Tapas** (`producttapas@substack.com`)
  - Focus: AI tools, product news, industry updates
  - Often covers: Claude, Cursor, Opus releases

## AI Strategy

- **Nate's Newsletter** (`natesnewsletter@substack.com`)
  - Focus: AI strategy, bottlenecks, industry analysis
  - Author: Nate Soares-style strategic thinking

## Product & Growth

- **Lenny's Newsletter** (`lenny@substack.com`)
  - Focus: Product management, growth, interviews
  - Most popular PM newsletter

- **Product Growth** (`aakashgupta@substack.com`, `news@aakashg.com`)
  - Focus: PM frameworks, AI PM, career development
  - Author: Aakash Gupta

## Leadership & Life

- **Dr. Becky Kennedy** (various)
  - Focus: Parenting, leadership parallels, emotional intelligence

## Community & Culture

- **Community Wisdom** (Lenny's Slack threads)
  - Format: Curated Slack discussions from Lenny's community

- **The Weekender** (Substack)
  - Format: Weekend reading, cultural commentary

---

## Search Patterns for gog CLI

The following search query fetches newsletters from the last 7 days:

```bash
QUERY="in:inbox (
  from:substack.com OR
  from:lennysnewsletter.com OR
  from:beehiiv.com OR
  from:producttapas OR
  from:natesnewsletter OR
  label:[Superhuman]/AI/AI_Newsletters_and_Content
) newer_than:7d"
```

**Customize this query to match your inbox structure and newsletter sources.**
