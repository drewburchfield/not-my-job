# Obfuscated Transaction Handling

Some payment methods obscure, truncate, or bundle merchant names. This file documents known patterns and how to extract the real merchant.

## Why This Matters

Without handling obfuscation:
- `PwP BACKBLAZE IPrivacycom...` won't match "Backblaze"
- `PAYPAL *SPOTIFY` won't group with direct Spotify charges
- `APPLE.COM/BILL` hides 5+ individual subscriptions

## Detection Strategy

**For ANY CSV, scan for known obfuscation patterns FIRST:**

```bash
# Quick detection - returns count of potentially obfuscated transactions
grep -cE "(PwP.*Privacycom|PAYPAL \*|PP\*|GOOGLE \*|SQ \*|VENMO|CASH APP\*|APPLE.COM/BILL)" [csv_file]
```

If count > 0, extract merchants before pattern detection.

## Known Obfuscation Patterns

### Virtual Card Services

| Service | Detection Pattern | Merchant Extraction | Notes |
|---------|-------------------|---------------------|-------|
| Privacy.com | `PwP.*Privacycom` | Between `PwP ` and `Privacycom` | Truncates to ~12-14 chars |
| Capital One Eno | `ENO.*` | Varies | Virtual card numbers |
| Citi Virtual | Varies | Check amount patterns | Less common |

**Privacy.com extraction:**
```bash
grep -oE "PwP [^P]+Privacycom" [csv] | sed 's/PwP //;s/Privacycom//' | sort -u
```

### Payment Processors

| Service | Detection Pattern | Merchant Extraction | Notes |
|---------|-------------------|---------------------|-------|
| PayPal | `PAYPAL \*` or `PP\*` | After `*` | Common for online purchases |
| Venmo | `VENMO \*` or `VENMO` | After `*` or payee name | P2P but also businesses |
| Cash App | `CASH APP\*` | After `*` | P2P and businesses |
| Zelle | `ZELLE` | Payee in description | Usually P2P |

**PayPal extraction:**
```bash
grep -oE "(PAYPAL \*|PP\*)[^,\"]*" [csv] | sed 's/PAYPAL \*//;s/PP\*//' | sort -u
```

### Mobile Payment / Wallets

| Service | Detection Pattern | Merchant Extraction | Notes |
|---------|-------------------|---------------------|-------|
| Google Pay | `GOOGLE \*` | After `*` | Could be Google service OR merchant |
| Apple Pay | Usually shows merchant | N/A | Typically transparent |
| Samsung Pay | Usually shows merchant | N/A | Typically transparent |

**Google Pay note:** `GOOGLE *` followed by:
- `You` = YouTube
- `Goo` = Google One/Workspace
- `PLAY` = Play Store
- Other = Merchant paid via Google Pay

### Point of Sale Systems

| Service | Detection Pattern | Merchant Extraction | Notes |
|---------|-------------------|---------------------|-------|
| Square | `SQ *` or `GOSQ.COM` | After `SQ *` | Small businesses |
| Toast | `TST*` | After `TST*` | Restaurants |
| Clover | Varies | Check merchant field | Restaurants/retail |

### Bundled Billing

| Service | Detection Pattern | What's Hidden | Action Required |
|---------|-------------------|---------------|-----------------|
| Apple | `APPLE.COM/BILL` or `APL*` | iOS app subscriptions | Check device Settings |
| Google | `GOOGLE PLAY` or `GOOGLE*PLAY` | Android app subscriptions | Check Play Store |
| Amazon | `AMZN Digital` | Kindle, Audible, channels | Check Amazon account |

**These CANNOT be unbundled from CSV.** Flag for user to check device/account.

## Processing Order

1. **Detect** - Scan CSV for any obfuscation patterns
2. **Extract** - Pull real merchant names using pattern-specific rules
3. **Deduplicate** - Same merchant via different methods = same subscription
4. **Identify** - Use reasoning to determine service (see SKILL.md)

## Common False Positives

These patterns often appear but aren't subscriptions:

| Pattern | Why Not Subscription |
|---------|---------------------|
| `PAYPAL *{PERSON}` | P2P payment to individual |
| `VENMO *{PERSON}` | P2P payment to individual |
| `SQ *{RESTAURANT}` | One-time food purchase |
| `GOOGLE *{MERCHANT}` | One-time purchase via Google Pay |

**Filter rule:** If payee appears to be a person's name OR amounts are highly variable with no pattern, likely not a subscription.

## Extending This File

When you encounter a new obfuscation pattern:
1. Document the detection pattern (regex)
2. Document how to extract the real merchant
3. Note any special handling required
4. Add to the detection scan command

This file should grow over time as new payment methods emerge.
