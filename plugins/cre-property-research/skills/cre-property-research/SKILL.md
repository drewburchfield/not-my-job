---
name: cre-property-research
description: Comprehensive commercial real estate property research and market analysis. Use when user requests property research, market analysis, tenant prospecting intelligence, or investment due diligence for any commercial property type (industrial, flex, office, retail, multifamily). Produces both conversational summary and detailed markdown brief with market comparisons, economic context, tenant acquisition strategy, competitive intelligence, and real-time data sources. Requires property address or listing document to begin.
---

# Commercial Real Estate Property Research

## Overview

This skill performs institutional-grade property research and market analysis for commercial real estate. It produces:
1. Conversational summary of key findings (immediate)
2. Comprehensive markdown research brief (saved to file)

**Scope:** All commercial property types (industrial, flex, office, retail, multifamily, land)

## First Step: Establish Current Date

**Before any research, get today's date.** This is critical for:
- Filtering search results to current year data
- Checking publication dates on sources
- Dating the research brief
- Ensuring market data is current

```bash
date "+%Y-%m-%d"
```

Record it: `Research date: [today's date]`

**Do NOT assume the year.** Claude defaults to outdated years in searches. Always include current year in queries (e.g., "Nashville industrial market [current year]").

## Research Framework

### Phase 1: Property Analysis

**Input Required:**
- Property address
- Listing document (PDF, flyer, offering memo) if available
- Property type (industrial, office, retail, etc.)

**Research:**
1. **Extract property specifications** from provided documents:
   - Address and size (SF)
   - Lease rate or sale price (per SF)
   - Year built or delivery date
   - Key features (ceiling height, power, loading, parking, etc.)
   - Developer/owner information
   - Zoning

2. **Calculate unit economics:**
   - Annual rent for various unit sizes
   - Monthly cash flow
   - Price per SF comparisons
   - NNN vs. gross lease implications

### Phase 2: Market Analysis

**Objective:** Determine if property pricing is competitive, premium, or undermarket.

**Research Steps:**

1. **Search current market inventory:**
   - Query: "[City] [Property Type] space for lease" or "for sale"
   - Sources: LoopNet, CommercialCafe, PropertyShark, CityFeet, Crexi
   - Document: Number of listings, average size, rental rates/SF, sale prices/SF

2. **Compare rates by property type:**

| Property Type | Typical Rate Range | What to Search |
|--------------|-------------------|----------------|
| Industrial/Warehouse | $6-10/SF annual lease | "industrial space for lease [city]" |
| Flex Space | $12-18/SF annual lease | "flex space for lease [city]" |
| Office (Class A) | $25-40/SF annual lease | "office space for lease [city]" |
| Office (Class B/C) | $18-28/SF annual lease | "office space for lease [city]" |
| Retail (Strip) | $18-30/SF annual lease | "retail space for lease [city]" |
| Retail (Mall) | $30-60/SF annual lease | "retail space for lease [city]" |
| Multifamily | Sale based on cap rate | "multifamily for sale [city]" |

3. **Document premium/discount:**
   - Calculate percentage above/below market average
   - Explain justification (new construction, location, features, etc.)

### Phase 3: Location & Economic Context

**Objective:** Understand what makes this location valuable.

**Research Areas:**

1. **Major economic drivers:**
   - Search: "[City] economic development [current year]"
   - Find: Major employers, recent expansions, economic impact data
   - Document: Largest employers, growth sectors, economic trends

2. **Infrastructure and connectivity:**
   - Proximity to highways, airports, ports, rail
   - Major nearby facilities (Amazon centers, manufacturing, military bases, etc.)
   - Commute patterns and workforce access

3. **Recent development activity:**
   - Search: "[City] [County] economic development corporation news"
   - Search: "[City] commercial real estate news [current year]"
   - Find: Recent announcements, pipeline projects, major investments
   - Document: Projects, timelines, job creation, investment amounts

4. **Population and demographics:**
   - Metro population and growth trends
   - Workforce size and characteristics
   - Income levels (for retail/multifamily especially)

### Phase 4: Tenant Prospecting Strategy

**Objective:** Identify specific, actionable tenant categories for leasing.

**For Industrial/Flex Properties:**

1. **Research local industry clusters:**
   - Manufacturing facilities in area
   - Distribution centers
   - Defense contractors (if near military base)
   - Logistics companies
   - E-commerce fulfillment

2. **Identify growth signals:**
   - Companies announcing expansions
   - New facilities under construction
   - Economic development pipeline projects
   - Incubators/accelerators graduating companies

3. **Size-specific opportunities:**
   - Small units (< 5,000 SF): Startups, veteran-owned businesses, small contractors
   - Medium units (5,000-20,000 SF): Growing mid-size companies
   - Large units (> 20,000 SF): Distribution, manufacturing, established firms

**For Office Properties:**

1. **Research employment trends:**
   - Companies hiring in area (LinkedIn job postings)
   - Headquarters relocations
   - Remote work vs. return-to-office trends
   - Professional services growth

2. **Industry-specific needs:**
   - Law firms (Class A preference)
   - Medical offices (ground floor, parking)
   - Tech companies (open floor plans, fiber)
   - Financial services (security, prestige)

**For Retail Properties:**

1. **Trade area analysis:**
   - Population density within 1/3/5 mile radius
   - Average household income
   - Existing retail mix
   - Traffic counts

2. **Tenant categories by rent tolerance:**
   - High-rent (> $40/SF): Restaurants, fitness, services
   - Mid-rent ($25-40/SF): Soft goods, specialty retail
   - Low-rent (< $25/SF): Services, discount retail

**For Multifamily:**

1. **Rental market analysis:**
   - Average rent by unit type (1BR, 2BR, 3BR)
   - Vacancy rates
   - Rent growth trends
   - Competing properties (age, amenities, pricing)

2. **Demand drivers:**
   - Job growth in area
   - Major employer hiring
   - Student population (if near university)
   - Military (if near base)

### Phase 5: Competitive Intelligence

**Objective:** Understand competitive landscape.

**Research:**

1. **Identify competing properties:**
   - Same property type within 3-5 miles
   - Similar size and features
   - Currently available for lease/sale

2. **Document competitive positioning:**
   - Age comparison (new vs. existing stock)
   - Feature comparison (ceiling height, power, parking, etc.)
   - Price comparison (premium, at-market, discount)
   - Availability (how long on market)

3. **Note differentiators:**
   - What does subject property have competitors don't?
   - What do competitors offer that subject doesn't?
   - Where is subject property clearly superior/inferior?

### Phase 6: Real-Time Data Sources

**Objective:** Identify ongoing prospecting and market intelligence sources.

**Government/Public Records:**

1. **Building permits:**
   - Search: "[County] building permits database"
   - Find: County inspection/permitting portal
   - Why: Identifies companies expanding (permit = future space need)

2. **Business registrations:**
   - State Secretary of State business search
   - New LLC/corporation filings
   - UCC financing statements (who's getting loans)

3. **Federal contracts (if defense/government market):**
   - SAM.gov for contract awards
   - Filter by location and date
   - Contract wins = expansion needs 6-12 months out

**Economic Development:**

1. **County/city economic development corporation:**
   - Active projects pipeline
   - Incentive programs
   - Business attraction efforts

2. **Local business publications:**
   - Search: "[City] business journal" or "Biz[City]"
   - Daily/weekly business news
   - Real estate transactions

**Industry-Specific:**

1. **LinkedIn intelligence:**
   - Job postings by location (hiring = growth)
   - Company page updates
   - Employee count trends
   - Executive moves

### Phase 7: Investment Analysis

**For Sale Properties:**

1. **Research cap rates:**
   - Search: "[City] commercial cap rates [current year] [property type]"
   - Compare to subject property's implied cap rate
   - Understand market expectations

2. **Calculate returns:**
   - Cap rate = NOI / Purchase Price
   - Cash-on-Cash = Annual Cash Flow / Equity Invested
   - Note: Full pro forma requires operating expense details

**For Lease Properties:**

1. **Landlord perspective:**
   - Effective rent (base + escalations + expense recovery)
   - Typical lease terms in market
   - Concessions (free rent, TI allowances)

2. **Tenant perspective:**
   - All-in occupancy cost (rent + NNN + utilities + buildout)
   - Compare to owning vs. leasing

## Output Structure

### Conversational Summary (In Chat)

Provide immediate 3-5 bullet point summary:
- Property type, size, price
- Market positioning (premium/at-market/discount + %)
- Top 2-3 tenant opportunities
- Most important competitive advantage
- Key risk or concern

### Markdown Research Brief (File)

**Save to:** `~/Documents/cre-research/[PROPERTY-NAME]-RESEARCH.md`

**Document Structure:**

```markdown
# [Property Name] - Market Research Brief

**Prepared for:** [Client/Partner Name]
**Property:** [Full Address]
**Date:** [Current Date]

---

## Executive Summary
[2-3 paragraph overview: property positioning, market context, key opportunities]

---

## Property Specifications
[Detailed specs table]

---

## Market Rate Comparison
[Rate comparison tables with sources]
[Premium/discount analysis]

---

## Developer Profile
[Developer background, experience, other projects]

---

## Location & Economic Context
[Major economic drivers, infrastructure, demographics]
[Recent development activity]

---

## Tenant Prospecting Strategy
[Priority target categories ranked]
[Market size, timeline, conversion probability for each]

---

## Competitive Intelligence
[Competing properties analysis]
[Competitive advantages/disadvantages]

---

## Real-Time Data Sources for Ongoing Prospecting
[Government records access]
[Economic development pipeline]
[Industry-specific intelligence sources]

---

## Investment Context
[Cap rates, returns analysis]
[Market fundamentals]

---

## Comprehensive Research Sources
[All sources organized by category with hyperlinks]
```

## Property Type Variations

### Industrial/Flex Space

**Focus on:**
- Ceiling height, loading doors, power (3-phase)
- Divisibility and unit mix
- Defense contractors, logistics, manufacturing tenants
- Proximity to military bases, airports, distribution hubs

### Office Space

**Focus on:**
- Class (A/B/C) and building quality
- Parking ratio (spaces per 1,000 SF)
- Professional services, tech companies, corporate tenants
- Commute access, amenities, prestige factors

### Retail Space

**Focus on:**
- Trade area demographics (population, income, traffic counts)
- Co-tenancy (anchor tenants, retail mix)
- Restaurant, fitness, service, goods tenants
- Visibility, parking, access

### Multifamily

**Focus on:**
- Unit mix (studio/1BR/2BR/3BR) and sizes
- Rent by unit type vs. market
- Amenities (pool, gym, pet-friendly, etc.)
- School districts, employment centers, lifestyle factors

## Research Quality Standards

**Market Rate Comparisons:**
- Minimum 3 comparable sources
- Cite all sources with hyperlinks
- Calculate percentage premium/discount
- Explain justification for pricing variance

**Economic Context:**
- Current year data only (use the date established in Phase 0)
- Cite authoritative sources (government, news, industry reports)
- Quantify impact where possible ($X billion, X jobs, etc.)

**Tenant Prospects:**
- Specific categories, not generic
- Rank by probability/fit
- Include market size estimates
- Provide actionable data sources to find these prospects

**Competitive Intelligence:**
- Name specific competing properties
- Document current availability and pricing
- Identify clear differentiators

## Common Pitfalls to Avoid

1. **Generic tenant categories** - Don't say "businesses needing space." Say "Defense contractors with Fort Bragg contracts needing 5,000-15,000 SF for equipment staging and light assembly."

2. **Stale data** - Always check publication dates. Prefer current year sources. Note when using older data.

3. **Missing the "so what"** - Don't just list facts. Explain why Fort Bragg's $8.8B impact matters for Gateway's tenant prospects.

4. **Overlooking local context** - National trends matter less than local drivers. Find the specific economic engines in THIS market.

5. **Ignoring existing development patterns** - If developer has other projects in area, research them. Patterns emerge.

## Reference Materials

For CRE terminology and concepts, see [CRE Glossary](references/cre-glossary.md) - load only if you need term clarification.

---

**Note:** This skill produces comprehensive research. For quick property lookups, use direct searches instead. This skill is for when depth and thoroughness matter.
