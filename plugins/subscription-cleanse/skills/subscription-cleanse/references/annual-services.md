# Known Annual Services

Services that typically bill annually. Flag ANY single charge from these merchants - don't require pattern detection.

## Contents

- **Cloud Storage & Backup** - Backblaze, Google One, iCloud+, Dropbox
- **Productivity & Finance** - YNAB, Quicken, Microsoft 365
- **Domains & Hosting** - GoDaddy, Namecheap, Cloudflare, Squarespace
- **Developer Tools** - GitHub Pro, JetBrains, Figma, Adobe CC
- **Security & Privacy** - 1Password, NordVPN, ExpressVPN
- **Memberships** - Amazon Prime, Costco, AAA, Walmart+
- **Professional & Learning** - LinkedIn Premium, Coursera, MasterClass
- **Detection Strategy** - How to catch single-charge annual subscriptions

---

## Cloud Storage & Backup

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| Backblaze | BACKBLAZE | $99/yr |
| Google One | GOOGLE *ONE, GOOGLE *STORAGE | $20-300/yr |
| iCloud+ | APPLE.COM/BILL (check amount) | $12-120/yr |
| Dropbox | DROPBOX | $120-240/yr |
| OneDrive | MICROSOFT*ONEDRIVE | $20-100/yr |

## Productivity & Finance

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| YNAB (You Need A Budget) | YNAB, YOU NEED A BUDGET | $99/yr |
| Quicken | QUICKEN | $36-104/yr |
| TurboTax Live | INTUIT*TURBOTAX | $50-200/yr |
| Microsoft 365 | MICROSOFT*365, MICROSOFT*OFFICE | $70-100/yr |

## Domains & Hosting

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| GoDaddy | GODADDY | $15-200/yr |
| Namecheap | NAMECHEAP | $10-50/yr |
| Google Domains | GOOGLE *DOMAINS | $12-60/yr |
| Cloudflare | CLOUDFLARE | $20-200/yr |
| Squarespace | SQUARESPACE | $144-276/yr |
| Wix | WIX.COM | $100-500/yr |

## Developer Tools

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| GitHub Pro | GITHUB | $48/yr |
| JetBrains | JETBRAINS | $149-649/yr |
| Figma | FIGMA | $144-540/yr |
| Adobe Creative Cloud | ADOBE | $120-660/yr |

## Security & Privacy

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| 1Password (annual) | 1PASSWORD, AGILEBITS | $36-60/yr |
| NordVPN | NORDVPN | $60-100/yr |
| ExpressVPN | EXPRESSVPN | $100/yr |
| Bitwarden | BITWARDEN | $10-40/yr |

## Memberships & Subscriptions

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| Amazon Prime | AMAZON PRIME, AMZN PRIME | $139/yr |
| Costco | COSTCO MEMBERSHIP | $65-130/yr |
| AAA | AAA MEMBERSHIP | $50-150/yr |
| Sam's Club | SAMS CLUB | $50-110/yr |
| Walmart+ | WALMART+ | $98/yr |

## Professional & Learning

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| LinkedIn Premium | LINKEDIN | $360-720/yr |
| Coursera Plus | COURSERA | $399/yr |
| MasterClass | MASTERCLASS | $120-180/yr |
| Audible (annual) | AUDIBLE | $150/yr |

## Health & Fitness (Annual)

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| Strava | STRAVA | $80/yr |
| MyFitnessPal | MYFITNESSPAL | $80/yr |
| AllTrails | ALLTRAILS | $36/yr |

## Media (Annual Plans)

| Service | Merchant Patterns | Typical Cost |
|---------|-------------------|--------------|
| YouTube Premium (annual) | GOOGLE *YOUTUBE | $140/yr |
| Spotify (annual) | SPOTIFY | $100-170/yr |
| Apple One (annual) | APPLE.COM/BILL | $170-400/yr |

---

## Detection Strategy

1. **Single charge from known annual service = Flag it**
   - Don't require 2+ occurrences
   - Don't require pattern matching
   - Even one charge means active subscription

2. **Check amount against typical cost**
   - If charge matches known annual range, likely annual
   - Monthly amounts from these services = different product

3. **Cross-reference with email**
   - Annual services send renewal notices 30-60 days before
   - Search: `from:@service.com subject:(renewal OR annual OR yearly)`

4. **Warn about data coverage**
   - If CSV covers < 12 months, will miss some annual subscriptions
   - Recommend 12-24 months of data for complete picture
