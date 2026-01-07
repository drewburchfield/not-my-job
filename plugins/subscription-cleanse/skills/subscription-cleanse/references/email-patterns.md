# Email Search Patterns

Gmail search patterns for subscription detection via GSuite-Enhanced MCP.

## Contents

- **GSuite-Enhanced MCP Tools** - API reference
- **Tier 1: High Confidence** - Receipts, invoices, renewal confirmations
- **Tier 2: Medium Confidence** - Trial warnings, payment reminders
- **Tier 3: Merchant-Specific** - Domain-based searches
- **Information Extraction** - What to pull from found emails
- **Search Optimization** - Reducing false positives
- **Failure Modes** - When email search misses subscriptions

---

## GSuite-Enhanced MCP Tools

```
query_emails(__user_id__="user@gmail.com", query="...")
get_email_by_id(__user_id__="user@gmail.com", email_id="...")
bulk_get_emails(__user_id__="user@gmail.com", message_ids=[...])
```

## Tier 1: High Confidence Subscription Indicators

These patterns strongly indicate active subscriptions:

### Receipt & Invoice Detection
```
subject:(receipt OR invoice) newer_than:12m
subject:"payment received" newer_than:12m
subject:"payment confirmation" newer_than:12m
subject:"billing statement" newer_than:12m
subject:"order confirmation" newer_than:12m
```

### Subscription Lifecycle
```
subject:"subscription renewed" newer_than:12m
subject:"membership renewed" newer_than:12m
"your subscription is active" newer_than:12m
"auto-renewal" newer_than:12m
"has been renewed" newer_than:12m
```

## Tier 2: Trial & Warning Indicators

Catch subscriptions before they charge:

### Trial Expiration
```
subject:("trial ending" OR "trial expires") newer_than:6m
subject:"trial will end" newer_than:6m
"free trial" "will be charged" newer_than:6m
"convert to paid" newer_than:6m
```

### Upcoming Charges
```
"your card will be charged" newer_than:6m
"upcoming charge" newer_than:6m
"upcoming payment" newer_than:6m
"will renew" newer_than:6m
subject:"payment reminder" newer_than:6m
```

### Price Changes
```
subject:"price increase" newer_than:12m
subject:"rate change" newer_than:12m
"your new rate" newer_than:12m
"price will change" newer_than:12m
```

## Tier 3: Welcome & Activation Emails

Indicates service is active (even if not recently charged):

### Welcome Emails
```
subject:"welcome to" -from:noreply@gmail.com newer_than:24m
subject:"thanks for subscribing" newer_than:24m
subject:"subscription confirmed" newer_than:24m
"your account is ready" newer_than:24m
"thank you for joining" newer_than:24m
```

### Account Activation
```
subject:"account activated" newer_than:24m
subject:"your membership" newer_than:12m
"premium access" newer_than:12m
```

## Tier 4: Cancellation & Changes (Historical)

Find previously cancelled services (avoid re-subscribing):

```
subject:"subscription cancelled" newer_than:12m
subject:"cancellation confirmed" newer_than:12m
"we're sorry to see you go" newer_than:12m
"plan changed" newer_than:12m
"downgrade" newer_than:12m
```

## Merchant-Specific Searches

After CSV analysis identifies merchants, search for context:

### Streaming
```
from:@netflix.com newer_than:12m
from:@spotify.com newer_than:12m
from:@hulu.com newer_than:12m
from:@disneyplus.com newer_than:12m
from:@hbomax.com newer_than:12m
```

### Software/Productivity
```
from:@adobe.com newer_than:12m
from:@microsoft.com subject:(billing OR subscription) newer_than:12m
from:@notion.so newer_than:12m
from:@dropbox.com newer_than:12m
from:@figma.com newer_than:12m
```

### AI Tools
```
from:@openai.com newer_than:12m
from:@anthropic.com newer_than:12m
from:@github.com subject:(copilot OR billing) newer_than:12m
```

### Telecom (Negotiable!)
```
from:@xfinity.com newer_than:6m
from:@att.com newer_than:6m
from:@spectrum.com newer_than:6m
from:@verizon.com newer_than:6m
from:@t-mobile.com newer_than:6m
```

## Cross-Reference Workflow

1. **Run CSV analysis first** - Identify all merchants from bank transactions
2. **For each merchant found:**
   - Search by sender domain: `from:@merchant.com`
   - Look for: Last activity, price changes, tier info
3. **Run broad searches** (Tier 1-3) to find services CSV might miss:
   - Free trials about to convert
   - Gift subscriptions
   - Services billed through app stores

## Email Signals for Categorization

### Cancel Signals (from email)
- No activity emails in 90+ days (e.g., weekly newsletters stopped)
- Price increase notifications
- Service deprecation notices
- "We miss you" re-engagement emails

### Keep Signals (from email)
- Recent activity notifications (watched, listened, used)
- Feature announcements you engaged with
- Password reset (indicates active use)

### Investigate Signals (from email)
- Trial ending soon
- Billing failed (may want to let it lapse)
- Plan change recommendations

### Negotiate Signals (from email)
- Rate increase notification from telecom
- "Loyalty offer" emails
- Contract renewal approaching

## Important Notes

### Timeframes
- Default: `newer_than:12m` for most searches
- Extended: `newer_than:24m` for annual subscriptions
- Short: `newer_than:6m` for trial detection

### Privacy
- All searches happen through user's authenticated GSuite-Enhanced MCP
- No email content leaves local machine
- Only extract: sender, subject, date, amount mentions

### Limitations
- Apple app store purchases: May need appleid.apple.com
- Google Play purchases: May need play.google.com/store/account
- PayPal recurring: Search `from:@paypal.com "recurring"`
