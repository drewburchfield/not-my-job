# CSV Parsing Reference

Comprehensive guide for parsing bank transaction data from various sources.

## Contents

- **Common Bank Export Formats** - Apple Card, Chase, Mint, Bank of America, Wells Fargo, Capital One, Discover, AmEx
- **Format Detection Algorithm** - How to identify bank format from headers/data
- **Parsing Large Files** - Chunked reading, sampling strategies
- **Merchant Name Normalization** - Patterns, algorithm, examples
- **Date Parsing** - Common formats, detection
- **Amount Parsing** - Currency handling, debit/credit detection
- **Error Handling** - Missing columns, malformed rows, encoding
- **Recurring Charge Detection** - Frequency analysis algorithm
- **Standard Banking Interchange Formats** - OFX, QFX, QIF, Plaid JSON, IIF, MT940
- **First-Principles Adaptive Parsing** - Unknown format handling, column inference

---

## Common Bank Export Formats

### Apple Card
**Export:** Wallet app → Card Balance → Export Transactions
**Format:** Standard CSV with headers

| Column | Type | Example |
|--------|------|---------|
| Transaction Date | Date (MM/DD/YYYY) | 01/05/2026 |
| Clearing Date | Date (MM/DD/YYYY) | 01/07/2026 |
| Description | Text | SPOTIFY USA |
| Merchant | Text | Spotify |
| Category | Text | Entertainment |
| Amount (USD) | Currency | -10.99 |

**Notes:**
- Amounts are negative for charges, positive for refunds
- Merchant field is normalized name
- Description has raw transaction text

### Chase
**Export:** Accounts → Download activity → CSV
**Format:** Multiple variants exist

| Column | Type | Example |
|--------|------|---------|
| Transaction Date | Date (MM/DD/YYYY) | 01/05/2026 |
| Post Date | Date (MM/DD/YYYY) | 01/06/2026 |
| Description | Text | NETFLIX.COM |
| Category | Text | Shopping |
| Type | Text | Sale |
| Amount | Currency | -15.99 |
| Memo | Text (optional) | Subscription |

**Notes:**
- Type: Sale (charge), Payment (payment), Return (refund)
- Amount can be positive (refund) or negative (charge)
- Some Chase exports have "Details" column instead of "Description"

### Mint
**Export:** Transactions → Export all transactions
**Format:** Comprehensive export

| Column | Type | Example |
|--------|------|---------|
| Date | Date (MM/DD/YYYY) | 01/05/2026 |
| Description | Text | Netflix |
| Original Description | Text | NETFLIX.COM 123456 |
| Amount | Currency | -15.99 |
| Transaction Type | Text | debit |
| Category | Text | Entertainment |
| Account Name | Text | Chase Freedom |
| Labels | Text (optional) | Subscription |
| Notes | Text (optional) | Monthly |

**Notes:**
- Amount: negative = expense, positive = income
- Transaction Type: debit, credit
- Original Description has raw merchant string
- Labels and Notes often empty

### Bank of America
**Export:** Accounts → Download Transactions → CSV
**Format:** Simple structure

| Column | Type | Example |
|--------|------|---------|
| Posted Date | Date (MM/DD/YYYY) | 01/06/2026 |
| Reference Number | Text | 1234567890 |
| Payee | Text | SPOTIFY USA |
| Address | Text (often empty) | |
| Amount | Currency | -10.99 |

**Notes:**
- No category column
- Payee is merchant name
- Amount negative for charges

### Wells Fargo
**Export:** Account Activity → Download → CSV
**Format:** Date-first structure

| Column | Type | Example |
|--------|------|---------|
| Date | Date (M/D/YYYY) | 1/5/2026 |
| Amount | Currency | -10.99 |
| * | Text (empty) | |
| * | Text (empty) | |
| Description | Text | SPOTIFY PREMIUM |

**Notes:**
- Has unnamed columns (usually empty)
- Simple format: Date, Amount, Description
- Amount negative for charges

### Capital One
**Export:** Transactions → Download
**Format:** Detailed transaction info

| Column | Type | Example |
|--------|------|---------|
| Transaction Date | Date (YYYY-MM-DD) | 2026-01-05 |
| Posted Date | Date (YYYY-MM-DD) | 2026-01-06 |
| Card No. | Text | 1234 |
| Description | Text | NETFLIX.COM |
| Category | Text | Merchandise |
| Debit | Currency | 15.99 |
| Credit | Currency | (empty) |

**Notes:**
- Uses ISO date format (YYYY-MM-DD)
- Separate Debit/Credit columns (use whichever is populated)
- Card No. is last 4 digits

### Discover
**Export:** Account Center → Download
**Format:** Similar to Chase

| Column | Type | Example |
|--------|------|---------|
| Trans. Date | Date (MM/DD/YYYY) | 01/05/2026 |
| Post Date | Date (MM/DD/YYYY) | 01/06/2026 |
| Description | Text | HULU LLC |
| Amount | Currency | 17.99 |
| Category | Text | Services |

**Notes:**
- Amount is positive for charges (unlike most banks)
- "Trans. Date" has period in column name

### American Express
**Export:** Statements & Activity → Download
**Format:** Detailed merchant info

| Column | Type | Example |
|--------|------|---------|
| Date | Date (MM/DD/YYYY) | 01/05/2026 |
| Description | Text | DISNEY PLUS |
| Card Member | Text | JOHN DOE |
| Account # | Text | ...1234 |
| Amount | Currency | -10.99 |

**Notes:**
- Amount negative for charges
- Card Member column useful for shared accounts
- Description usually clean merchant name

## Format Detection Algorithm

### Step 1: Read First Line (Headers)

```python
# Read first line to get column names
headers = first_line.strip().split(',')
headers_lower = [h.strip().lower() for h in headers]
```

### Step 2: Identify Key Columns

**Date column candidates:**
- "date", "transaction date", "trans. date", "posted date", "post date", "clearing date"

**Merchant/Description candidates:**
- "description", "merchant", "payee", "original description", "details"

**Amount candidates:**
- "amount", "amount (usd)", "debit", "credit", "total"

**Category candidates (optional):**
- "category", "type", "transaction type"

### Step 3: Infer Format

```python
# Apple Card signature
if 'merchant' in headers_lower and 'clearing date' in headers_lower:
    format = 'apple_card'

# Chase signature
elif 'post date' in headers_lower and 'type' in headers_lower:
    format = 'chase'

# Mint signature
elif 'original description' in headers_lower:
    format = 'mint'

# Capital One signature (ISO dates)
elif 'transaction date' in headers_lower and first_data_line matches YYYY-MM-DD:
    format = 'capital_one'

# Discover signature (period in column name)
elif 'trans. date' in headers_lower:
    format = 'discover'

# Generic fallback
else:
    format = 'generic'
    # Use best-match heuristics
```

## Parsing Large Files

### Chunked Reading

For files > 10MB or > 50k transactions:

```python
# Don't load entire file into memory
# Process in chunks of 1000 rows
CHUNK_SIZE = 1000

with open(csv_path, 'r') as f:
    reader = csv.DictReader(f)
    chunk = []

    for row in reader:
        chunk.append(row)

        if len(chunk) >= CHUNK_SIZE:
            process_chunk(chunk)
            chunk = []

    # Process remaining
    if chunk:
        process_chunk(chunk)
```

### Sampling for Large Files

If file is very large (>100MB), sample it first:

```python
# Quick analysis on first 5000 + last 1000 rows
# This captures recent subscriptions (last 1000)
# Plus historical patterns (first 5000)

head_sample = read_first_n_rows(5000)
tail_sample = read_last_n_rows(1000)
combined_sample = head_sample + tail_sample
```

## Merchant Name Normalization

### Common Patterns

| Raw Transaction | Normalized | Pattern |
|----------------|------------|---------|
| SPOTIFY USA 123456 | SPOTIFY | Remove country codes, reference numbers |
| NETFLIX.COM | NETFLIX | Remove .com, .net, etc |
| AMZN MKTP US*1A2B3C | AMAZON | AMZN → Amazon, remove marketplace codes |
| GOOGLE *YOUTUBE | YOUTUBE | Split on *, take second part |
| SQ *COFFEE SHOP | COFFEE SHOP | Square payments pattern |
| TST* RESTAURANT | RESTAURANT | Toast payments pattern |
| APL*APPLE.COM/BILL | APPLE | Apple billing pattern |
| PAYPAL *SERVICENAME | SERVICENAME | PayPal pattern |

### Normalization Algorithm

```python
def normalize_merchant(raw):
    """Normalize merchant name for grouping."""

    # Remove common prefixes
    raw = re.sub(r'^(SQ|TST|PP|PYMT)\s*\*\s*', '', raw)

    # Handle Google services
    if 'GOOGLE *' in raw:
        return raw.split('GOOGLE *')[1].strip()

    # Handle PayPal
    if 'PAYPAL *' in raw:
        return raw.split('PAYPAL *')[1].strip()

    # Handle Apple billing
    if 'APL*APPLE.COM/BILL' in raw or 'APPLE.COM/BILL' in raw:
        return 'APPLE'

    # Amazon variations
    if raw.startswith('AMZN'):
        return 'AMAZON'

    # Remove domains
    raw = re.sub(r'\.(com|net|org|io)/?', '', raw, flags=re.IGNORECASE)

    # Remove trailing reference numbers
    raw = re.sub(r'\s+\d{5,}$', '', raw)

    # Remove country codes
    raw = re.sub(r'\s+(USA|US|UK|CA)$', '', raw, flags=re.IGNORECASE)

    # Remove card processor codes
    raw = re.sub(r'\s+\d{2,4}-\d{4}$', '', raw)

    # Uppercase and trim
    return raw.strip().upper()
```

## Date Parsing

### Common Formats

| Format | Example | strptime |
|--------|---------|----------|
| MM/DD/YYYY | 01/05/2026 | %m/%d/%Y |
| M/D/YYYY | 1/5/2026 | %m/%d/%Y |
| YYYY-MM-DD | 2026-01-05 | %Y-%m-%d |
| DD/MM/YYYY | 05/01/2026 | %d/%m/%Y |
| MM-DD-YYYY | 01-05-2026 | %m-%d-%Y |

### Detection

```python
def parse_date(date_str):
    """Try common date formats."""
    formats = [
        '%m/%d/%Y',   # US standard
        '%m/%d/%y',   # US 2-digit year
        '%Y-%m-%d',   # ISO format
        '%d/%m/%Y',   # International
        '%m-%d-%Y',   # Dash variant
    ]

    for fmt in formats:
        try:
            return datetime.strptime(date_str.strip(), fmt)
        except ValueError:
            continue

    raise ValueError(f"Could not parse date: {date_str}")
```

## Amount Parsing

### Handling Currency Symbols

```python
def parse_amount(amount_str):
    """Parse amount, handling various formats."""

    # Remove currency symbols and whitespace
    clean = re.sub(r'[$£€,\s]', '', amount_str)

    # Handle parentheses for negative (accounting format)
    if '(' in clean and ')' in clean:
        clean = '-' + clean.replace('(', '').replace(')', '')

    # Convert to float
    try:
        return float(clean)
    except ValueError:
        return 0.0
```

### Debit/Credit Detection

Some banks use separate columns:

```python
# Capital One style
if row['Debit']:
    amount = -abs(float(row['Debit']))
elif row['Credit']:
    amount = abs(float(row['Credit']))

# Chase style (unified Amount column)
else:
    amount = parse_amount(row['Amount'])
```

## Error Handling

### Missing Columns

```python
# If expected column missing, try alternatives
date_candidates = ['Date', 'Transaction Date', 'Posted Date', 'Trans. Date']
date_col = next((col for col in date_candidates if col in headers), None)

if not date_col:
    raise ValueError("Could not identify date column")
```

### Malformed Rows

```python
# Skip rows with missing critical data
if not row.get(date_col) or not row.get(amount_col):
    continue  # Skip this transaction

# Handle empty merchant names
merchant = row.get(merchant_col) or row.get(desc_col) or 'UNKNOWN'
```

### Encoding Issues

```python
# Try UTF-8 first, fallback to latin-1
try:
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
except UnicodeDecodeError:
    with open(csv_path, 'r', encoding='latin-1') as f:
        reader = csv.DictReader(f)
```

## Recurring Charge Detection

### Frequency Analysis

```python
# Group by normalized merchant
transactions_by_merchant = defaultdict(list)

for tx in all_transactions:
    merchant = normalize_merchant(tx['merchant'])
    transactions_by_merchant[merchant].append(tx['date'])

# Check for recurring patterns
for merchant, dates in transactions_by_merchant.items():
    if len(dates) < 2:
        continue

    # Sort dates
    dates.sort()

    # Calculate intervals between transactions
    intervals = [
        (dates[i+1] - dates[i]).days
        for i in range(len(dates)-1)
    ]

    # Monthly: 28-32 days
    if all(28 <= interval <= 32 for interval in intervals):
        frequency = 'monthly'

    # Annual: 350-380 days
    elif all(350 <= interval <= 380 for interval in intervals):
        frequency = 'annual'

    # Quarterly: 85-95 days
    elif all(85 <= interval <= 95 for interval in intervals):
        frequency = 'quarterly'

    # Irregular but multiple charges
    else:
        frequency = 'irregular'
```

## Quick Reference: Detection Checklist

When parsing unknown CSV:

1. **Read first 5 lines** - Get headers + sample data
2. **Identify date column** - Look for date patterns in column names and values
3. **Identify merchant column** - "description", "merchant", "payee"
4. **Identify amount column** - May be one column or Debit/Credit split
5. **Detect amount sign convention** - Negative for charges vs positive for charges
6. **Detect date format** - Try parsing first date value
7. **Check for encoding issues** - Non-ASCII characters garbled?
8. **Count rows** - If >10k, use chunked processing

## Special Cases

### PayPal CSV
- Separate "Gross" and "Fee" columns
- "Name" column is merchant (not "Description")
- "Type" column distinguishes subscription vs one-time

### Venmo CSV
- "Note" column has description
- Amount split into "Amount (total)" and "Amount (fee)"
- "Type" is Payment or Charge

### Cash App
- Very simple: Date, Type, Currency, Amount, Status, Name, Note
- "Type" is Cash In/Cash Out/Bitcoin

## Testing Format Detection

After implementing detection logic, test with:
1. 1-2 sample rows from each bank format
2. Edge cases: empty columns, special characters, large amounts
3. Date format ambiguity (is 03/04/2026 March 4 or April 3?)

---

## Standard Banking Interchange Formats

Beyond CSV, banks export in standardized interchange formats. These are more structured and reliable than CSV.

### OFX (Open Financial Exchange)

**Extension:** `.ofx`, `.qfx` (Quicken variant)
**Format:** SGML (v1.x) or XML (v2.x)
**Standard since:** 1997, now managed by Financial Data Exchange (FDX)

**Structure:**
```xml
<OFX>
  <BANKMSGSRSV1>
    <STMTTRNRS>
      <STMTRS>
        <BANKTRANLIST>
          <STMTTRN>
            <TRNTYPE>DEBIT</TRNTYPE>
            <DTPOSTED>20260105</DTPOSTED>
            <TRNAMT>-15.99</TRNAMT>
            <FITID>9947030000068</FITID>
            <NAME>NETFLIX.COM</NAME>
            <MEMO>Subscription payment</MEMO>
          </STMTTRN>
        </BANKTRANLIST>
      </STMTRS>
    </STMTTRNRS>
  </BANKMSGSRSV1>
</OFX>
```

**Key Tags:**
| Tag | Description | Example |
|-----|-------------|---------|
| `<TRNTYPE>` | Transaction type | DEBIT, CREDIT, XFER, PAYMENT, OTHER |
| `<DTPOSTED>` | Posted date | YYYYMMDD format (20260105) |
| `<TRNAMT>` | Amount | Signed decimal (-15.99) |
| `<FITID>` | Unique transaction ID | Bank's internal reference |
| `<NAME>` | Payee/merchant name | Raw merchant string |
| `<MEMO>` | Additional description | Optional details |

**Parsing Notes:**
- OFX 1.x is SGML (tags don't need closing)
- OFX 2.x is proper XML
- Dates are YYYYMMDD (no separators)
- Amounts already signed (negative = outflow)
- FITID is unique - use for deduplication

### QIF (Quicken Interchange Format)

**Extension:** `.qif`
**Format:** Plain text, line-based
**Note:** Older format, no unique transaction IDs

**Structure:**
```
!Type:Bank
D01/05/2026
T-15.99
NNETFLIX
MSubscription payment
^
D01/03/2026
T-10.99
NSPOTIFY
MMonthly subscription
^
```

**Field Codes:**
| Code | Description |
|------|-------------|
| `!Type:` | Account type (Bank, CCard, Cash, etc.) |
| `D` | Date |
| `T` | Amount |
| `N` | Payee/check number |
| `M` | Memo |
| `P` | Payee (alternative to N) |
| `L` | Category |
| `^` | End of record |

**Parsing Notes:**
- Each record ends with `^`
- Date format varies (MM/DD/YY or MM/DD/YYYY)
- No unique IDs - cannot deduplicate reliably
- Amount already signed

### Plaid Transaction Format

**Format:** JSON (via API)
**Source:** Aggregated from banks via Plaid API
**Used by:** Many fintech apps export Plaid-format JSON

**Structure:**
```json
{
  "transaction_id": "kgygNvAVPzSX5k5q5pqjkNPYq9N1NVH6PK5n9",
  "account_id": "BxBXxLj1m4HMXBm9WZZmCWVbPjX16EHwv99vp",
  "amount": 15.99,
  "date": "2026-01-05",
  "datetime": "2026-01-05T00:00:00Z",
  "name": "NETFLIX.COM",
  "merchant_name": "Netflix",
  "merchant_entity_id": "netflix_entity_id",
  "pending": false,
  "payment_channel": "online",
  "personal_finance_category": {
    "primary": "ENTERTAINMENT",
    "detailed": "ENTERTAINMENT_TV_AND_MOVIES",
    "confidence_level": "VERY_HIGH"
  },
  "location": {
    "city": null,
    "region": null,
    "country": "US"
  },
  "iso_currency_code": "USD"
}
```

**Key Fields:**
| Field | Description |
|-------|-------------|
| `transaction_id` | Unique identifier |
| `amount` | Positive = outflow, negative = inflow |
| `date` | YYYY-MM-DD format |
| `name` | Raw merchant (lightly cleaned) |
| `merchant_name` | Enriched/normalized name |
| `personal_finance_category` | Plaid's categorization |
| `pending` | True if not yet posted |

**Parsing Notes:**
- Amount sign is OPPOSITE of most banks (positive = charge)
- `merchant_name` is pre-normalized - use when available
- `personal_finance_category` can assist categorization
- Dates are ISO 8601 (YYYY-MM-DD)

### QuickBooks IIF Format

**Extension:** `.iif`
**Format:** Tab-separated values with headers
**Note:** QuickBooks Desktop only

**Structure:**
```
!TRNS	TRNSID	TRNSTYPE	DATE	ACCNT	NAME	AMOUNT	MEMO
!SPL	SPLID	TRNSTYPE	DATE	ACCNT	NAME	AMOUNT	MEMO
!ENDTRNS
TRNS		GENERAL JOURNAL	01/05/2026	Checking	Netflix	-15.99	Subscription
SPL		GENERAL JOURNAL	01/05/2026	Entertainment		15.99	Subscription
ENDTRNS
```

**Notes:**
- Tab-delimited
- Requires exact account name matching
- Two-sided entries (TRNS + SPL)
- Less common for export, mainly for import

### MT940 (SWIFT Format)

**Extension:** `.mt940`, `.sta`
**Format:** SWIFT message format
**Used by:** European/international banks

**Structure:**
```
:20:STMT123456
:25:DE89370400440532013000
:28C:00001/001
:60F:C260104EUR1234,56
:61:2601050105D15,99NNETFLIX//123456
:86:NETFLIX SUBSCRIPTION
:62F:C260105EUR1218,57
```

**Key Tags:**
| Tag | Description |
|-----|-------------|
| `:61:` | Transaction line (date, amount, type, ref) |
| `:86:` | Transaction details/memo |
| `:60F:` | Opening balance |
| `:62F:` | Closing balance |

**Parsing Notes:**
- Dates are YYMMDD format
- Amount format: `D15,99` (D=debit, C=credit)
- European decimal notation (comma)
- Reference follows `//`

---

## First-Principles Adaptive Parsing Strategy

When encountering an unknown format, apply these principles:

### Core Truth: All Transaction Data Has the Same DNA

Every transaction format must contain:
1. **When** - Date/time of transaction
2. **How much** - Amount
3. **Who/what** - Merchant/payee/description
4. **Direction** - Inflow or outflow

Everything else is metadata.

### The Universal Detection Algorithm

```python
def identify_transaction_fields(data):
    """
    First-principles approach to identify transaction fields
    regardless of format.
    """

    # 1. DETECT FORMAT TYPE
    if isinstance(data, str):
        if data.strip().startswith('<OFX') or data.strip().startswith('OFXHEADER'):
            return parse_ofx(data)
        elif data.strip().startswith('!Type:'):
            return parse_qif(data)
        elif data.strip().startswith(':20:'):
            return parse_mt940(data)
        elif '\t' in data.split('\n')[0] and '!TRNS' in data:
            return parse_iif(data)
        else:
            return parse_csv_or_text(data)
    elif isinstance(data, dict):
        return parse_json(data)  # Plaid-style
    elif isinstance(data, list):
        return [identify_transaction_fields(item) for item in data]

    # 2. FOR CSV/TEXT: Identify columns by content patterns
    # (see below)
```

### Column Identification by Content Analysis

When headers don't match known patterns, analyze the DATA:

```python
def infer_column_types(headers, sample_rows):
    """
    Infer column purposes from actual data patterns.
    """
    column_types = {}

    for i, header in enumerate(headers):
        values = [row[i] for row in sample_rows if row[i]]

        # DATE detection: Try parsing as date
        if all(looks_like_date(v) for v in values[:5]):
            column_types[i] = 'date'

        # AMOUNT detection: Numeric with optional currency symbol
        elif all(looks_like_amount(v) for v in values[:5]):
            column_types[i] = 'amount'

        # DESCRIPTION detection: Mostly text, variable length
        elif avg_length(values) > 10 and not_all_numeric(values):
            column_types[i] = 'description'

    return column_types


def looks_like_date(value):
    """Check if value looks like a date."""
    # Patterns: MM/DD/YYYY, YYYY-MM-DD, DD/MM/YYYY, YYYYMMDD
    patterns = [
        r'\d{1,2}/\d{1,2}/\d{2,4}',  # MM/DD/YYYY or M/D/YY
        r'\d{4}-\d{2}-\d{2}',         # YYYY-MM-DD (ISO)
        r'\d{8}',                      # YYYYMMDD
        r'\d{1,2}-\d{1,2}-\d{2,4}',   # MM-DD-YYYY
    ]
    return any(re.match(p, str(value).strip()) for p in patterns)


def looks_like_amount(value):
    """Check if value looks like a currency amount."""
    clean = re.sub(r'[$€£,\s()]', '', str(value))
    try:
        float(clean.replace(',', '.'))  # Handle European decimals
        return True
    except ValueError:
        return False
```

### Handling Claude Code's 25k Token Limit

For files larger than Claude Code can read directly:

**Strategy 1: Smart Sampling**
```python
# Read first 100 lines (headers + recent transactions)
head_sample = read_lines(file_path, n=100)

# Read last 100 lines (oldest transactions for annual detection)
tail_sample = read_tail_lines(file_path, n=100)

# Middle sample for pattern verification
middle_sample = read_lines_at_offset(file_path, offset=line_count//2, n=50)
```

**Strategy 2: Line Count First**
```bash
# Get line count without reading file
wc -l statement.csv

# If >1000 lines, sample strategically
head -100 statement.csv > sample_head.csv
tail -100 statement.csv > sample_tail.csv
```

**Strategy 3: Grep for Patterns**
```bash
# Find subscription-like merchants without reading whole file
grep -i "netflix\|spotify\|hulu\|subscription" statement.csv | head -50
```

**Strategy 4: Process in Bash, Report to Claude**
```bash
# Extract unique merchants and their frequency
cut -d',' -f3 statement.csv | sort | uniq -c | sort -rn | head -50
```

### Universal Transaction Normalizer

After parsing any format, normalize to common structure:

```python
@dataclass
class NormalizedTransaction:
    date: datetime
    amount: float          # Always negative for outflows
    merchant_raw: str      # Original merchant string
    merchant_normalized: str  # Cleaned/normalized
    description: str       # Full description/memo
    category: str | None   # If provided by source
    transaction_id: str | None  # For deduplication
    source_format: str     # 'csv', 'ofx', 'qif', 'plaid', etc.


def normalize_transaction(raw, source_format):
    """Convert any format to normalized structure."""

    # Normalize amount sign (negative = outflow)
    if source_format == 'plaid':
        # Plaid: positive = outflow (opposite of banks)
        amount = -raw['amount'] if raw['amount'] > 0 else raw['amount']
    else:
        # Most banks: negative = outflow
        amount = raw['amount']

    # Use best available merchant name
    merchant_raw = raw.get('name') or raw.get('merchant') or raw.get('description', '')
    merchant_normalized = (
        raw.get('merchant_name') or  # Plaid enriched
        raw.get('merchant') or       # Apple Card
        normalize_merchant(merchant_raw)  # Fallback to our normalizer
    )

    return NormalizedTransaction(
        date=parse_date(raw['date']),
        amount=amount,
        merchant_raw=merchant_raw,
        merchant_normalized=merchant_normalized,
        description=raw.get('memo') or raw.get('description') or '',
        category=raw.get('category') or raw.get('personal_finance_category', {}).get('primary'),
        transaction_id=raw.get('transaction_id') or raw.get('fitid'),
        source_format=source_format
    )
```

### Decision Tree for Unknown Formats

```
Is it a file?
├── Extension is .ofx or .qfx?
│   └── Parse as OFX (check SGML vs XML)
├── Extension is .qif?
│   └── Parse as QIF (look for !Type: header)
├── Extension is .iif?
│   └── Parse as IIF (tab-separated, !TRNS headers)
├── Extension is .json?
│   └── Parse as JSON (check for Plaid-like structure)
├── Extension is .csv or .txt?
│   └── Analyze content:
│       ├── Has headers? Match to known banks
│       ├── No match? Infer columns from data
│       └── Still unclear? Ask user to identify columns
└── Unknown extension?
    └── Read first 1KB, detect format from content
```

### Regional Format Variations

**US Banks:**
- Date: MM/DD/YYYY
- Amount: $1,234.56 (comma thousands, dot decimal)
- Sign: Usually negative = charge

**European Banks:**
- Date: DD/MM/YYYY or DD.MM.YYYY
- Amount: 1.234,56€ (dot thousands, comma decimal)
- Sign: Varies

**UK Banks:**
- Date: DD/MM/YYYY
- Amount: £1,234.56 (like US)
- Sign: Usually negative = charge

**Detection:**
```python
def detect_regional_format(sample_amounts, sample_dates):
    # Check decimal separator
    if ',' in sample_amounts[0] and '.' not in sample_amounts[0]:
        decimal_sep = ','  # European
    else:
        decimal_sep = '.'  # US/UK

    # Check date format by finding month > 12
    for date in sample_dates:
        parts = re.split(r'[/.-]', date)
        if len(parts) == 3:
            if int(parts[0]) > 12:
                return 'dmy', decimal_sep  # European
            elif int(parts[1]) > 12:
                return 'mdy', decimal_sep  # US

    return 'mdy', decimal_sep  # Default to US
```

---

## Sources

Standard format specifications:
- [Open Financial Exchange (Wikipedia)](https://en.wikipedia.org/wiki/Open_Financial_Exchange)
- [QFX file format (Wikipedia)](https://en.wikipedia.org/wiki/QFX_(file_format))
- [Quicken Interchange Format (Wikipedia)](https://en.wikipedia.org/wiki/Quicken_Interchange_Format)
- [Plaid Transactions API](https://plaid.com/docs/api/products/transactions/)
- [OFX Banking Specification](https://financialdataexchange.org)
