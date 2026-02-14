---
name: meeting-prep
description: Prepare a comprehensive briefing for a meeting with a specific person. Combines person research with mutual connection search into talking points.
---

# Meeting Prep

**Purpose:** Create a comprehensive briefing before a meeting with someone. Combines a full person research profile with a mutual connection search to give you everything you need: background, employment history, shared connections, talking points, and social links.

**Cost formula:** 3 credits (1 research + 2 search)

## When to Use This Skill

Use when:
- User says "I have a meeting with [person]" or "brief me on [person]"
- User is preparing for a call, interview, or networking event with a specific person
- User wants a comprehensive profile with mutual connections and talking points

Don't use when:
- User just wants a basic research profile (use `/happenstance` research)
- User wants to find people, not prep for a known person (use `/deep-search`)
- User wants mutual connections for intro purposes (use `/warm-intro`)

## Workflow

### STEP 1: Parse the Request

Extract:
- **Person description** (required): name, company, title, social handles
- **Meeting context** (optional): what the meeting is about, any specific topics to focus on

Ask for more identifiers if the user only provides a name. The more detail, the better the research match.

### STEP 2: Credit Check

Call `mcp__happenstance__get-credits`.

Present cost:
```
Meeting prep for [Person] will cost 3 credits:
- 1 credit for person research (full profile)
- 2 credits for mutual connection search
You currently have [balance] credits. Proceed?
```

If balance < 3, inform the user. Offer to do research-only (1 credit) if they have at least 1.

### STEP 3: Research the Person

Call `mcp__happenstance__research-person` with the full description.

**Fallback:**
```bash
cd "${CLAUDE_PLUGIN_ROOT}/skills/happenstance/scripts"
source lib.sh
RESULT=$(./happenstance-api.sh research "Name, Title at Company, @handle")
RESEARCH_ID=$(echo "$RESULT" | jq -r '.id')
```

### STEP 4: Search for Mutual Connections

While research is processing, start the mutual connection search. Call `mcp__happenstance__search-network` with:
- `query`: person's name + company (e.g., "Garry Tan Y Combinator")
- `includeFriends`: true
- `includeConnections`: true

This finds the person in your network and surfaces mutual connections.

### STEP 5: Poll Both

Poll both `mcp__happenstance__get-research-results` and `mcp__happenstance__get-search-results` every 5-10 seconds until both are complete.

### STEP 6: Compile Briefing

Combine research profile + mutual connections into a meeting briefing:

```
## Meeting Briefing: [Person Name]
**[Title] at [Company]** | [Location]
Prepared: [today's date]

---

### At a Glance
[2-3 sentence AI summary from research]

### Background

**Current Role:** [Title] at [Company] ([start date] - present)

**Career History:**
- [Company] - [Title] (dates)
- [Company] - [Title] (dates)
- ...

**Education:**
- [School] - [Degree] (dates)

### Mutual Connections
[If search found mutuals:]
You share [N] mutual connections:
- **[Name]** - [Title] at [Company] (affinity: [score])
- **[Name]** - [Title] at [Company]
- ...

[If no mutuals found:]
No mutual connections found in your network.

### Talking Points
Based on their profile, here are potential conversation topics:

1. **[Topic from projects/writings]** - [brief context]
2. **[Topic from recent role/company]** - [brief context]
3. **[Topic from hobbies/interests]** - [brief context]
4. **[Shared connection topic]** - You both know [mutual], could be a good opener

### Links
- LinkedIn: [url]
- Twitter: [url]
- Other: [urls]

### Notes
[Meeting context if user provided it]
[Any flags: e.g., "Research returned FAILED_AMBIGUOUS, profile may be incomplete"]
```

## Error Handling

- **Research fails (FAILED):** Still present whatever search results were found, note the research gap
- **Research fails (FAILED_AMBIGUOUS):** Ask user for more details, offer to retry with better description
- **Search returns no results:** Present research profile without mutuals section
- **Both fail:** Inform user, suggest verifying the person's details

## Best Practices

1. Start research and search in parallel to save time
2. Generate talking points from research data (projects, writings, hobbies are great conversation starters)
3. Highlight mutual connections prominently since they're natural conversation openers
4. Include today's date on the briefing for freshness context
5. If user mentions the meeting topic, tailor talking points to that context
6. Link to the person's social profiles so user can quickly review before the meeting
