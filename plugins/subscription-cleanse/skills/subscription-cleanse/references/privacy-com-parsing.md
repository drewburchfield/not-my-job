# Privacy.com Transaction Parsing

**Part of:** [obfuscated-transactions.md](obfuscated-transactions.md) (see parent doc for overall approach)

Privacy.com is a virtual card service that truncates merchant names to ~12-14 characters.

## Role of This File

This is a **lookup accelerator** for Privacy.com specifically. It provides:
1. Known truncation → full name mappings
2. Disambiguation rules for multi-product vendors
3. False positive filters

For the general approach to obfuscated transactions, see the parent doc.

## Contents

- **Transaction Format** - How Privacy.com transactions appear
- **Truncation Mappings** - Known merchant name truncations (extensible)
- **Disambiguation Guide** - Vendors with multiple products
- **Parsing Strategy** - How to extract and match merchants
- **Common False Positives** - Non-subscription merchants to filter

---

## Transaction Format

**Pattern:** `PwP {MERCHANT_TRUNCATED}Privacycom{YYMMDD}TN: {ID}WEB`

**Example:**
```
PwP CLAUDE.AI SPrivacycom251229TN: 1525989WEB
    ^^^^^^^^^^^ merchant (truncated to ~12-14 chars)
              ^^^^^^^^^^^^ privacy.com identifier
                        ^^^^^^ date (YYMMDD)
                              ^^^^^^^^^^ transaction ID
```

**Key insight:** Merchant names are truncated to ~12-14 characters, often mid-word.

## Truncation Mappings

### AI & Developer Tools

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `CLAUDE.AI S` | Claude AI (Anthropic) | $20-220/mo |
| `OPENAI *CHA` | OpenAI ChatGPT Plus | $20-22/mo |
| `CURSOR USAG` | Cursor (AI code editor) | $13-20/mo |
| `COGNITION L` | Cognition Labs (Devin) | Varies |
| `WISPR` | Wispr AI | Varies |

### Streaming & Entertainment

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `GOOGLE *You` | YouTube TV/Premium | $68-90/mo |
| `Google YouT` | YouTube (alternate) | Varies |
| `Netflix.com` | Netflix | $15-23/mo |
| `NETFLIX.COM` | Netflix (uppercase) | $15-23/mo |
| `SPOTIFY` | Spotify | $11-17/mo |

### Cloud & Productivity

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `GOOGLE *Goo` | Google One/Workspace | $3-220/mo |
| `CLOUDFLARE` | Cloudflare | $5-200/mo |
| `BACKBLAZE I` | Backblaze Backup | $9/mo or $99/yr |
| `MAILSTROM S` | Mailstrom (email cleanup) | $10-50/yr |
| `SANEBOX: EM` | SaneBox (email mgmt) | $7-36/mo |

### Professional & News

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `LinkedInPre` | LinkedIn Premium | $30-60/mo |
| `LENNYS NEWS` | Lenny's Newsletter | $150-350/yr |
| `FANTASYPROS` | FantasyPros | $10-40/mo seasonal |

### Health & Lifestyle

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `WAKING UP C` | Waking Up (meditation) | $100-130/yr |
| `SP WHOOP IN` | Whoop (fitness tracker) | $30/mo or $239/yr |

### Finance & Budgeting

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `YOU NEED A` | YNAB (You Need A Budget) | $99-120/yr |

### Home & Network

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `EERO PLUS -` | Eero Plus (wifi security) | $10/mo or $100/yr |
| `DAKBOARD, L` | DAKboard (smart display) | $6-8/mo or $96/yr |
| `RING STANDA` | Ring Protect (home security) | $100-200/yr |

### Retail Memberships

| Truncated | Full Service | Typical Amount |
|-----------|--------------|----------------|
| `COSTCO *ANN` | Costco Annual Membership | $65-130/yr |
| `WMT PLUS 20` | Walmart+ | $98/yr or $13/mo |

### Utilities (Not Subscriptions - But Recurring)

| Truncated | Full Service | Notes |
|-----------|--------------|-------|
| `ATMOS ENERG` | Atmos Energy (gas utility) | Monthly bill, negotiable |

### Resellers (Check Email for Actual Service)

| Truncated | Notes |
|-----------|-------|
| `PADDLE.NET*` | Paddle payment processor - could be any SaaS |
| `2COCOM*HTTP` | 2Checkout - SaaS reseller, check email for actual service |

### Unknown (Flag for User)

| Truncated | Notes |
|-----------|-------|
| `INNOVATION` | Unknown - 10 charges at $100 in sample data, needs user verification |

---

## Disambiguation Guide

Some vendors have multiple products. Use **amount** as the primary disambiguation signal.

### Google Services

| Truncated | Amount Range | Likely Service |
|-----------|--------------|----------------|
| `GOOGLE *Goo` | $1.99-2.99/mo | Google One 100GB |
| `GOOGLE *Goo` | $2.99-9.99/mo | Google One 200GB-2TB |
| `GOOGLE *Goo` | $19.99-99.99/yr | Google One annual |
| `GOOGLE *Goo` | $6-18/user/mo | Google Workspace |
| `GOOGLE *Goo` | $100-300 one-time | Google One annual (higher tier) or Workspace annual |
| `GOOGLE *You` | $11-15/mo | YouTube Premium or Music |
| `GOOGLE *You` | $23/mo | YouTube Premium Family |
| `GOOGLE *You` | $65-90/mo | YouTube TV |
| `Google YouT` | (same as above) | Alternate YouTube truncation |

### Apple Services

Apple charges typically show as `APPLE.COM/BILL` (not Privacy.com), but if routed through Privacy:

| Amount Range | Likely Service |
|--------------|----------------|
| $0.99-9.99/mo | iCloud+, Apple Arcade, News+, Fitness+ |
| $10.99-16.99/mo | Apple Music, TV+ |
| $22.95-37.95/mo | Apple One bundles |

### Amazon Services

| Truncated | Amount Range | Likely Service |
|-----------|--------------|----------------|
| `AMAZON PRIM` | $14.99/mo | Prime Monthly |
| `AMAZON PRIM` | $139/yr | Prime Annual |
| `AMZN MKTP` | varies | Regular shopping (not subscription) |
| `AMAZON WEB` | varies | AWS (usage-based) |

### Microsoft Services

| Truncated | Amount Range | Likely Service |
|-----------|--------------|----------------|
| `MICROSOFT*` | $9.99-12.99/mo | Microsoft 365 Personal |
| `MICROSOFT*` | $12.99-19.99/mo | Microsoft 365 Family |
| `MICROSOFT*` | $99-149/yr | Microsoft 365 annual |
| `XBOX` | $10-15/mo | Xbox Game Pass |

### When Amount Doesn't Disambiguate

If amount is ambiguous:
1. Check email receipts for the service name
2. Note both possibilities in output: "Google One or Workspace ($219.49)"
3. Flag for user verification if critical

## Parsing Strategy

### Step 1: Detect & Extract

```python
# Detect Privacy.com transaction
is_privacy = "PwP " in description and "Privacycom" in description

# Extract truncated merchant (between "PwP " and "Privacycom")
match = re.search(r'PwP (.+?)Privacycom', description)
truncated_merchant = match.group(1).strip() if match else None

# Extract date (YYMMDD format)
date_match = re.search(r'Privacycom(\d{6})', description)
```

### Step 2: Identify Service (Hierarchy)

**Level 1 - Mapping Table (this file):**
- Check truncation mappings above
- Exact match → use mapped name
- Partial match → use with note

**Level 2 - Claude's World Knowledge:**
For unknown truncations, reason about:
- What company does this name suggest?
- Is this a known SaaS/subscription service?
- Does the amount match typical subscription pricing?

Most subscription services are in Claude's training data. Example reasoning:
- `BACKBLAZE I` → Backblaze (cloud backup), ~$99/yr
- `WAKING UP C` → Waking Up (meditation app by Sam Harris), ~$100/yr
- `COGNITION L` → Cognition Labs (Devin AI), developer tool

**Level 3 - Disambiguation:**
Use amount to distinguish multi-product vendors (see Disambiguation Guide above)

**Level 4 - Web Search (if available):**
When uncertain and tools available:
- Search: "[truncated name] subscription service"
- Search: "[truncated name] pricing"

**Level 5 - User Verification:**
When unable to identify:
- Note truncated name, amount, charge count
- Mark as "Unknown - needs verification"

### Step 3: Output with Confidence

```
Netflix [CSV-PRIVACY] - $19.70/mo
Backblaze [CSV-PRIVACY/inferred] - $198/yr - cloud backup
Google One [CSV-PRIVACY/disambiguated] - $219.49 - 2TB annual (amount-based)
INNOVATION [CSV-PRIVACY/unknown] - $100 × 10 - NEEDS VERIFICATION
```

## Common False Positives

These merchants appear frequently via Privacy.com but are NOT subscriptions:

| Truncated | Why Not a Subscription |
|-----------|------------------------|
| `WALMART.COM` | Regular shopping |
| `WAL-MART #0` | In-store shopping |
| `WWW COSTCO` | Regular shopping (not membership) |
| `CHICK-FIL-A` | Food |
| `DOMINOS` | Food |
| `O'REILLY` | Auto parts |
| `CUMBERLAND` | Gas station |

**Filtering rule:** If merchant appears in shopping/food categories with high variance in amounts, likely not a subscription.

## Integration with Main Skill

When Privacy.com transactions are detected:

1. Apply truncation mapping before merchant normalization
2. Note source as `[CSV-PRIVACY]` to indicate potential truncation uncertainty
3. If unknown truncated merchant has recurring pattern, categorize as "Investigate" not "Cancel"
4. Flag for email cross-reference: `from:@[guessed-domain].com`
